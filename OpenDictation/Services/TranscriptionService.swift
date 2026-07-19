import Foundation

/// Orchestrates a transcription request: resolves the API key, assembles the
/// configuration, and hands off to the active provider.
@MainActor
final class TranscriptionService {
    private let provider: any TranscriptionProvider
    private let keyStore: any APIKeyStoring
    private let environment: [String: String]

    /// - Parameter environment: injectable for tests; defaults to the process
    ///   environment so developers can smoke-test headlessly (see `resolveAPIKey`).
    init(
        provider: any TranscriptionProvider,
        keyStore: any APIKeyStoring,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.provider = provider
        self.keyStore = keyStore
        self.environment = environment
    }

    func transcribe(audioFileURL: URL) async throws -> Transcript {
        guard let apiKey = resolveAPIKey(),
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.missingAPIKey
        }

        // Model becomes user-selectable when Settings lands in Milestone 7.
        let configuration = TranscriptionConfiguration(
            apiKey: apiKey,
            model: OpenAITranscriptionProvider.defaultModel
        )
        return try await provider.transcribe(audioFileURL: audioFileURL, configuration: configuration)
    }

    /// The Keychain is the real store. The environment override exists purely
    /// for development/CI, where seeding a keychain isn't practical.
    private func resolveAPIKey() -> String? {
        if let key = environment["OPENDICTATION_OPENAI_API_KEY"] ?? environment["OPENAI_API_KEY"],
           !key.isEmpty {
            return key
        }
        return try? keyStore.key(for: provider.id)
    }
}
