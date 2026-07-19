import Foundation

/// A backend capable of turning recorded audio into text.
///
/// OpenAI is *an* implementation, never *the* implementation: adding a future
/// provider means one new type conforming to this protocol and nothing else.
protocol TranscriptionProvider: Sendable {
    /// Stable identifier, e.g. "openai". Used for history records and key storage.
    var id: String { get }

    /// Human-readable name for Settings, e.g. "OpenAI".
    var displayName: String { get }

    /// Transcribes the audio file at `audioFileURL`.
    /// - Throws: `AppError` describing the failure in user-presentable terms.
    func transcribe(audioFileURL: URL, configuration: TranscriptionConfiguration) async throws -> Transcript
}

/// Per-request settings a provider needs. Assembled by the caller (from
/// Settings + Keychain once those milestones land).
struct TranscriptionConfiguration: Sendable {
    var apiKey: String
    var model: String
    /// ISO-639-1 hint (e.g. "en"); `nil` lets the provider auto-detect.
    var language: String?

    init(apiKey: String, model: String, language: String? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.language = language
    }
}
