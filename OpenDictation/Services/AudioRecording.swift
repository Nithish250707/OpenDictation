import Foundation

/// Capability: capture microphone audio to a temporary file with live level
/// metering. Main-actor bound — recording control is inherently tied to UI
/// state and the underlying AVAudioRecorder is not thread-safe.
@MainActor
protocol AudioRecording: AnyObject {
    var isRecording: Bool { get }

    /// Resolves the microphone permission, prompting the user if it has never
    /// been asked. Returns `false` when access is (or has been) denied.
    func requestPermission() async -> Bool

    /// Starts a new recording and returns the temporary file it writes to.
    func startRecording() throws -> URL

    /// Stops the active recording and returns its file, or `nil` if nothing
    /// was being recorded.
    func stopRecording() -> URL?

    /// Latest input level, normalized to 0…1 for waveform rendering.
    func currentPowerLevel() -> Float
}
