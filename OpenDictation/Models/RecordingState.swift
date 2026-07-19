import Foundation

/// The dictation flow's state machine.
///
/// ```
/// idle ──▶ recording ──▶ transcribing ──▶ transcript ──▶ (Done) idle
///   │                         │
///   │                         └──▶ failed ──(Retry)──▶ transcribing
///   └──▶ permissionDenied ──▶ (reset) idle
/// ```
enum RecordingState: Equatable {
    case idle
    case recording(startedAt: Date)
    case transcribing(audioFileURL: URL, duration: TimeInterval)
    case transcript(Transcript)
    /// Keeps the recorded file (when there is one) so Retry never loses a take.
    case failed(error: AppError, audioFileURL: URL?, duration: TimeInterval)
    case permissionDenied

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
}
