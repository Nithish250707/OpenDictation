import Foundation

/// User-presentable errors. Every failure that reaches a view model is mapped
/// into one of these so the UI always has a friendly, actionable message.
enum AppError: LocalizedError, Equatable {
    // Recording
    case microphonePermissionDenied
    case audioRecordingFailed
    case audioFileUnreadable

    // Paste
    case accessibilityPermissionDenied
    case pasteFailed

    // Transcription
    case missingAPIKey
    case invalidAPIKey
    case unsupportedAudio
    case rateLimited(retryAfter: TimeInterval?)
    case networkUnavailable
    case requestTimedOut
    case serverError(statusCode: Int)
    case providerError(message: String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "Microphone access is required to dictate."
        case .audioRecordingFailed:
            "Recording couldn't be started. Please try again."
        case .audioFileUnreadable:
            "The recording could not be read. Please try again."
        case .accessibilityPermissionDenied:
            "Accessibility access is required to paste into other apps."
        case .pasteFailed:
            "Couldn't paste automatically. Use Copy, then press ⌘V in the target app."
        case .missingAPIKey:
            "Add your API key in Settings to enable transcription."
        case .invalidAPIKey:
            "Your API key was rejected. Check it in Settings."
        case .unsupportedAudio:
            "The recording format wasn't accepted. Please try again."
        case .rateLimited:
            "The transcription service is busy. Wait a moment and retry."
        case .networkUnavailable:
            "No internet connection. Check your network and retry."
        case .requestTimedOut:
            "The request timed out. Check your connection and retry."
        case .serverError:
            "The transcription service had a problem. Try again shortly."
        case .providerError(let message):
            message
        }
    }

    /// A terse, capsule-sized summary for the recording HUD, where the full
    /// `errorDescription` sentence would be too long to read at a glance.
    var hudSummary: String {
        switch self {
        case .microphonePermissionDenied: "Microphone access needed"
        case .audioRecordingFailed: "Recording failed"
        case .audioFileUnreadable: "Recording unreadable"
        case .accessibilityPermissionDenied: "Accessibility access needed"
        case .pasteFailed: "Couldn't paste — copied instead"
        case .missingAPIKey: "Add your API key in Settings"
        case .invalidAPIKey: "API key rejected — check Settings"
        case .unsupportedAudio: "Audio format not accepted"
        case .rateLimited: "Service busy — try again"
        case .networkUnavailable: "No internet connection"
        case .requestTimedOut: "Request timed out"
        case .serverError: "Service error — try again"
        case .providerError: "Transcription failed"
        }
    }
}
