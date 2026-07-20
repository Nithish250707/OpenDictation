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
    /// True only when the automatic copy actually reached the clipboard —
    /// the UI must not claim "Copied" on the strength of the setting alone.
    private(set) var autoCopied = false
    /// Live mirror of `AXIsProcessTrusted()`, refreshed on app-active and
    /// while watching for a grant. The Paste button and the guidance banner
    /// derive from this — never from a cached "was denied once" flag.
    private(set) var accessibilityGranted = false
    /// Per-transcript UI dismissal of the guidance banner ("Not Now").
    private(set) var accessibilityHelpDismissed = false
    private(set) var pasteErrorMessage: String?

    /// Show the Accessibility guidance when Paste is unavailable and the user
    /// hasn't dismissed it. Disappears the instant the permission is granted.
    var shouldShowAccessibilityHelp: Bool {
        !accessibilityGranted && !accessibilityHelpDismissed
    }

    private let audio: any AudioRecording
    private let transcription: TranscriptionService
    private let pasteboard: any PasteboardServicing
    private let paste: any PasteServicing
    private let accessibility: any AccessibilityPermissionChecking
    private let settings: SettingsStore
    private let history: any HistoryStoring
    private var meterTask: Task<Void, Never>?
    private var copyFeedbackTask: Task<Void, Never>?
    private var pasteFeedbackTask: Task<Void, Never>?
    private var accessibilityWatchTask: Task<Void, Never>?
    /// Guards against a second `startRecording` racing the first through the
    /// async permission gap (e.g. the shortcut pressed twice quickly).
    private var isStarting = false

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
        self.accessibilityGranted = accessibility.isGranted
    }

    // MARK: - Recording

    func startRecording() async {
        guard case .idle = state, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        // Remember the app the user is dictating from, while it's still
        // frontmost, so a later auto-paste lands there — not in Open Dictation.
        paste.captureTarget()

        guard await audio.requestPermission() else {
            state = .permissionDenied
            return
        }
        // The permission await yields the main actor; re-check that nothing
        // else moved the state machine meanwhile.
        guard case .idle = state else { return }

        do {
            _ = try audio.startRecording()
            elapsed = 0
            levels = Array(repeating: 0, count: Self.waveformBarCount)
            state = .recording(startedAt: .now)
            startMetering()
        } catch {
            Log.audio.error("Could not start recording: \(error.localizedDescription)")
            // Surface the failure instead of silently vanishing.
            state = .failed(error: .audioRecordingFailed, audioFileURL: nil, duration: 0)
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
            Log.paste.info("Transcript finished (\(transcript.text.count, privacy: .public) chars)")
            // The finished transcript goes straight to the clipboard so the
            // user can ⌘V immediately, even before touching the popup.
            if settings.autoCopy {
                autoCopied = pasteboard.copy(transcript.text)
                Log.paste.info("Clipboard updated = \(self.autoCopied, privacy: .public)")
                if !autoCopied {
                    pasteErrorMessage = "Couldn't copy to the clipboard automatically. Use the Copy button."
                }
            }
            // History must never block the dictation flow; a failed save is
            // logged and the transcript still reaches the user.
            do {
                try history.save(transcript)
            } catch {
                Log.app.error("Couldn't save transcript to history: \(error.localizedDescription)")
            }
            // Fresh transcript: re-read the live permission so the Paste
            // button and banner are correct, and reset the per-transcript
            // banner dismissal.
            accessibilityHelpDismissed = false
            refreshAccessibilityPermission()
            // While a transcript is shown without permission, watch for a grant
            // so the banner clears and Paste enables live — no matter how the
            // user grants it (our button, System Settings, etc.).
            if !accessibilityGranted { startAccessibilityWatch() }
            state = .transcript(transcript)
            Log.paste.info("autoPaste enabled = \(self.settings.autoPaste, privacy: .public), accessibility = \(self.accessibilityGranted, privacy: .public)")
            if settings.autoPaste {
                Log.paste.info("Attempting auto-paste")
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
        // Cancel any previous feedback timer so a rapid second click can't be
        // cleared early by the first click's timer.
        copyFeedbackTask?.cancel()
        copyFeedbackTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1_500))
            guard !Task.isCancelled else { return }
            self?.justCopied = false
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
            pasteFeedbackTask?.cancel()
            pasteFeedbackTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(1_500))
                guard !Task.isCancelled else { return }
                self?.justPasted = false
            }
        } catch AppError.accessibilityPermissionDenied {
            // The single source of truth said no. Reflect it live and start
            // watching for the grant so the banner clears the moment it lands.
            refreshAccessibilityPermission()
            startAccessibilityWatch()
        } catch {
            // The transcript is already on the clipboard (auto-copied), so a
            // synthesis failure still leaves the user one ⌘V away.
            pasteErrorMessage = AppError.pasteFailed.localizedDescription
        }
    }

    /// Re-reads `AXIsProcessTrusted()` — the single source of truth for the
    /// Accessibility permission. Call on app-active, when the transcript
    /// appears, and while watching for a grant.
    func refreshAccessibilityPermission() {
        accessibilityGranted = accessibility.isGranted
        Log.paste.info("Refreshed Accessibility permission: granted=\(self.accessibilityGranted, privacy: .public)")
        if accessibilityGranted {
            // A stale "couldn't paste" message must not outlive the grant.
            if pasteErrorMessage == AppError.pasteFailed.localizedDescription {
                pasteErrorMessage = nil
            }
            accessibilityWatchTask?.cancel()
            accessibilityWatchTask = nil
        }
    }

    func openAccessibilitySettings() {
        accessibility.openSystemSettings()
        // The recorder panel doesn't reliably receive app-active events, so
        // poll for the grant while the user is over in System Settings.
        startAccessibilityWatch()
    }

    func dismissAccessibilityHelp() {
        accessibilityHelpDismissed = true
    }

    private func startAccessibilityWatch() {
        guard accessibilityWatchTask == nil, !accessibilityGranted else { return }
        accessibilityWatchTask = Task { [weak self] in
            // ~60s of polling; refreshAccessibilityPermission cancels early on grant.
            for _ in 0..<75 {
                try? await Task.sleep(for: .milliseconds(800))
                guard let self, !Task.isCancelled else { return }
                self.refreshAccessibilityPermission()
                if self.accessibilityGranted { return }
            }
            self?.accessibilityWatchTask = nil
        }
    }

    /// Returns to `.idle`, deleting any audio that no longer has a purpose —
    /// no dictation audio should linger on disk.
    func reset() {
        stopMetering()
        copyFeedbackTask?.cancel()
        copyFeedbackTask = nil
        pasteFeedbackTask?.cancel()
        pasteFeedbackTask = nil
        accessibilityWatchTask?.cancel()
        accessibilityWatchTask = nil
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
        autoCopied = false
        accessibilityHelpDismissed = false
        pasteErrorMessage = nil
        refreshAccessibilityPermission()
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
        // Instant attack, gentle decay: peaks land immediately but fall away
        // smoothly, which reads far more naturally than raw meter samples.
        let raw = audio.currentPowerLevel()
        let previous = levels.last ?? 0
        levels.append(max(raw, previous * 0.82))
    }
}
