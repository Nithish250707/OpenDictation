import Foundation

/// User-presentable errors. Every failure that reaches a view model is mapped
/// into one of these so the UI always has a friendly, actionable message.
enum AppError: LocalizedError, Equatable {
    // Recording
    case microphonePermissionDenied
    case audioRecordingFailed
    case audioFileUnreadable

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
}
