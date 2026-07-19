import Foundation

/// User-presentable errors. Every failure that reaches a view model is mapped
/// into one of these so the UI always has a friendly, actionable message.
/// Grows as milestones add capabilities (network, provider, keychain…).
enum AppError: LocalizedError {
    case microphonePermissionDenied
    case audioRecordingFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "Microphone access is required to dictate."
        case .audioRecordingFailed:
            "Recording couldn't be started. Please try again."
        }
    }
}
