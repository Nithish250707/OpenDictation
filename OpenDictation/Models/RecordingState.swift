import Foundation

/// The recording flow's state machine.
///
/// ```
/// idle ──▶ recording ──▶ stopped ──▶ (reset) idle
///   └──▶ permissionDenied ──▶ (reset) idle
/// ```
enum RecordingState: Equatable {
    case idle
    case recording(startedAt: Date)
    case stopped(audioFileURL: URL, duration: TimeInterval)
    case permissionDenied

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
}
