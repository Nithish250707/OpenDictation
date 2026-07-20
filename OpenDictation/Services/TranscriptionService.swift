import Foundation

/// Orchestrates a transcription request: resolves the active provider and
/// model from Settings, resolves the API key, and hands off to the provider.
@MainActor
final class TranscriptionService {
    private let registry: ProviderRegistry
    private let keyStore: any APIKeyStoring
    private let settings: SettingsStore
    private let environment: [String: String]

    /// - Parameter environment: injectable for tests; defaults to the process
    ///   environment so developers can smoke-test headlessly (see `resolveAPIKey`).
    init(
        registry: ProviderRegistry,
        keyStore: any APIKeyStoring,
        settings: SettingsStore,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.registry = registry
        self.keyStore = keyStore
        self.settings = settings
        self.environment = environment
    }

    func transcribe(audioFileURL: URL) async throws -> Transcript {
        let provider = registry.provider(id: settings.providerID) ?? registry.default

        guard let apiKey = resolveAPIKey(for: provider.id),
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.missingAPIKey
        }

        // A persisted model can go stale (provider switched, model retired);
        // fall back to the provider's default rather than failing the request.
        let model = provider.supportedModels.contains(settings.model)
            ? settings.model
            : provider.defaultModel

        let configuration = TranscriptionConfiguration(
            apiKey: apiKey,
            model: model,
            language: settings.languageCode
        )
        return try await provider.transcribe(audioFileURL: audioFileURL, configuration: configuration)
    }

    /// The Keychain is the real store. The environment override exists purely
    /// for development/CI, where seeding a keychain isn't practical.
    ///
    /// This is the **only** protected (decrypting) Keychain read in the app,
    /// reached only while actually transcribing — never from the UI. It goes
    /// through `CachedAPIKeyStore`, so the Keychain is touched at most once per
    /// process (and not at all when the key was entered earlier this session,
    /// since saving pre-populates the cache).
    private func resolveAPIKey(for providerID: String) -> String? {
        if let key = environment["OPENDICTATION_OPENAI_API_KEY"] ?? environment["OPENAI_API_KEY"],
           !key.isEmpty, providerID == "openai" {
            return key
        }
        return try? keyStore.key(for: providerID)
    }
}
