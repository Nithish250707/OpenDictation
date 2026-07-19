import Foundation
import Observation

/// State and intent for the recording popup: drives the state machine
/// (`RecordingState`), the elapsed timer, the waveform level buffer, and the
/// transcription workflow.
@MainActor
@Observable
final class RecordingViewModel {
    static let waveformBarCount = 36

    private(set) var state: RecordingState = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var levels: [Float]
    /// Briefly true after Copy / Paste, so the buttons can acknowledge the action.
    private(set) var justCopied = false
    private(set) var justPasted = false
    /// Set when Paste was attempted without Accessibility permission;
    /// the transcript view shows inline guidance while this is true.
    private(set) var needsAccessibilityPermission = false
    private(set) var pasteErrorMessage: String?

    private let audio: any AudioRecording
    private let transcription: TranscriptionService
    private let pasteboard: any PasteboardServicing
    private let paste: any PasteServicing
    private let accessibility: any AccessibilityPermissionChecking
    private let settings: SettingsStore
    private let history: any HistoryStoring
    private var meterTask: Task<Void, Never>?

    init(
        audio: any AudioRecording,
        transcription: TranscriptionService,
        pasteboard: any PasteboardServicing,
        paste: any PasteServicing,
        accessibility: any AccessibilityPermissionChecking,
        settings: SettingsStore,
        history: any HistoryStoring
    ) {
        self.audio = audio
        self.transcription = transcription
        self.pasteboard = pasteboard
        self.paste = paste
        self.accessibility = accessibility
        self.settings = settings
        self.history = history
        self.levels = Array(repeating: 0, count: Self.waveformBarCount)
    }

    // MARK: - Recording

    func startRecording() async {
        guard case .idle = state else { return }

        guard await audio.requestPermission() else {
            state = .permissionDenied
            return
        }

        do {
            _ = try audio.startRecording()
            elapsed = 0
            levels = Array(repeating: 0, count: Self.waveformBarCount)
            state = .recording(startedAt: .now)
            startMetering()
        } catch {
            Log.audio.error("Could not start recording: \(error.localizedDescription)")
            state = .idle
        }
    }

    /// Stops the recording and immediately hands the audio to transcription.
    func stopAndTranscribe() {
        guard case .recording(let startedAt) = state else { return }
        stopMetering()

        let duration = Date.now.timeIntervalSince(startedAt)
        guard let url = audio.stopRecording() else {
            state = .failed(error: .audioRecordingFailed, audioFileURL: nil, duration: 0)
            return
        }
        Task { await transcribe(audioFileURL: url, duration: duration) }
    }

    // MARK: - Transcription

    func retry() {
        guard case .failed(_, let audioFileURL?, let duration) = state else { return }
        Task { await transcribe(audioFileURL: audioFileURL, duration: duration) }
    }

    private func transcribe(audioFileURL: URL, duration: TimeInterval) async {
        state = .transcribing(audioFileURL: audioFileURL, duration: duration)

        do {
            var transcript = try await transcription.transcribe(audioFileURL: audioFileURL)
            guard isStillTranscribing(audioFileURL) else { return }
            // The recorder's file length is authoritative; providers fall back
            // to probing the file, which can fail for exotic formats.
            if transcript.duration == 0 { transcript.duration = duration }
            deleteAudioFile(at: audioFileURL)
            // The finished transcript goes straight to the clipboard so the
            // user can ⌘V immediately, even before touching the popup.
            if settings.autoCopy {
                pasteboard.copy(transcript.text)
            }
            // History must never block the dictation flow; a failed save is
            // logged and the transcript still reaches the user.
            do {
                try history.save(transcript)
            } catch {
                Log.app.error("Couldn't save transcript to history: \(error.localizedDescription)")
            }
            state = .transcript(transcript)
            if settings.autoPaste {
                pasteTranscript()
            }
        } catch {
            guard isStillTranscribing(audioFileURL) else { return }
            let appError = (error as? AppError) ?? .providerError(message: error.localizedDescription)
            state = .failed(error: appError, audioFileURL: audioFileURL, duration: duration)
        }
    }

    /// The user may dismiss the popup while a request is in flight; a stale
    /// result must not resurrect the UI afterwards.
    private func isStillTranscribing(_ audioFileURL: URL) -> Bool {
        if case .transcribing(let url, _) = state, url == audioFileURL { return true }
        return false
    }

    // MARK: - Transcript actions

    func copyTranscript() {
        guard case .transcript(let transcript) = state else { return }
        guard pasteboard.copy(transcript.text) else {
            pasteErrorMessage = "Couldn't copy to the clipboard. Please try again."
            return
        }
        pasteErrorMessage = nil
        justCopied = true
        Task {
            try? await Task.sleep(for: .milliseconds(1_500))
            justCopied = false
        }
    }

    /// Pastes the transcript into the app the user was dictating in.
    /// Explicit user action only — never triggered automatically.
    func pasteTranscript() {
        guard case .transcript(let transcript) = state else { return }
        pasteErrorMessage = nil
        do {
            try paste.pasteToFocusedApp(transcript.text)
            justPasted = true
            Task {
                try? await Task.sleep(for: .milliseconds(1_500))
                justPasted = false
            }
        } catch AppError.accessibilityPermissionDenied {
            needsAccessibilityPermission = true
        } catch {
            // The transcript is already on the clipboard (auto-copied), so a
            // synthesis failure still leaves the user one ⌘V away.
            pasteErrorMessage = AppError.pasteFailed.localizedDescription
        }
    }

    func openAccessibilitySettings() {
        accessibility.openSystemSettings()
    }

    func dismissAccessibilityHelp() {
        needsAccessibilityPermission = false
    }

    /// Returns to `.idle`, deleting any audio that no longer has a purpose —
    /// no dictation audio should linger on disk.
    func reset() {
        stopMetering()
        switch state {
        case .transcribing(let url, _):
            deleteAudioFile(at: url)
        case .failed(_, let url?, _):
            deleteAudioFile(at: url)
        default:
            break
        }
        state = .idle
        elapsed = 0
        justCopied = false
        justPasted = false
        needsAccessibilityPermission = false
        pasteErrorMessage = nil
        levels = Array(repeating: 0, count: Self.waveformBarCount)
    }

    private func deleteAudioFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Metering

    private func startMetering() {
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                self?.tick()
            }
        }
    }

    private func stopMetering() {
        meterTask?.cancel()
        meterTask = nil
    }

    private func tick() {
        guard case .recording(let startedAt) = state else { return }
        // Derive elapsed from the start date rather than accumulating ticks,
        // so timer drift can't build up over a long dictation.
        elapsed = Date.now.timeIntervalSince(startedAt)
        levels.removeFirst()
        levels.append(audio.currentPowerLevel())
    }
}
