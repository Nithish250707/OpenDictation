import Foundation

/// The catalog of available transcription providers.
///
/// Adding a provider to the app = implement `TranscriptionProvider` in one
/// new file and append it to `live()`. Settings, the model picker, and the
/// transcription pipeline all read from here — no other changes needed.
struct ProviderRegistry: Sendable {
    let all: [any TranscriptionProvider]

    init(providers: [any TranscriptionProvider]) {
        precondition(!providers.isEmpty, "ProviderRegistry needs at least one provider")
        self.all = providers
    }

    /// Fallback when a persisted provider ID no longer exists.
    var `default`: any TranscriptionProvider { all[0] }

    func provider(id: String) -> (any TranscriptionProvider)? {
        all.first { $0.id == id }
    }

    static func live() -> ProviderRegistry {
        ProviderRegistry(providers: [
            OpenAITranscriptionProvider(),
            // Future: Anthropic, Gemini, Groq, Deepgram, AssemblyAI,
            // whisper.cpp, MLX Whisper, Ollama…
        ])
    }
}
