import Foundation
import Observation

/// State and intent for the recording popup. Drives the state machine
/// (`RecordingState`), the elapsed timer, and the waveform level buffer.
@MainActor
@Observable
final class RecordingViewModel {
    static let waveformBarCount = 36

    private(set) var state: RecordingState = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var levels: [Float]

    private let audio: any AudioRecording
    private var meterTask: Task<Void, Never>?

    init(audio: any AudioRecording) {
        self.audio = audio
        self.levels = Array(repeating: 0, count: Self.waveformBarCount)
    }

    func startRecording() async {
        guard case .idle = state else { return }

        guard await audio.requestPermission() else {
            state = .permissionDenied
            return
        }

        do {
            _ = try audio.startRecording()
            state = .recording(startedAt: .now)
            startMetering()
        } catch {
            Log.audio.error("Could not start recording: \(error.localizedDescription)")
            state = .idle
        }
    }

    func stopRecording() {
        guard case .recording(let startedAt) = state else { return }
        stopMetering()

        if let url = audio.stopRecording() {
            state = .stopped(audioFileURL: url, duration: Date.now.timeIntervalSince(startedAt))
        } else {
            state = .idle
        }
    }

    /// Returns to `.idle`, discarding any finished recording. Until
    /// transcription exists (Milestone 4) the audio has no consumer, so it is
    /// deleted immediately — no dictation audio should linger on disk.
    func reset() {
        stopMetering()
        if case .stopped(let url, _) = state {
            try? FileManager.default.removeItem(at: url)
        }
        state = .idle
        elapsed = 0
        levels = Array(repeating: 0, count: Self.waveformBarCount)
    }

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
