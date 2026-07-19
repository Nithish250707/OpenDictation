import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct TranscriptionServiceTests {
    private let audioURL = URL(fileURLWithPath: "/dev/null")

    private func makeService(
        provider: MockTranscriptionProvider,
        keys: [String: String] = [:],
        environment: [String: String] = [:],
        configure: (SettingsStore) -> Void = { _ in }
    ) -> TranscriptionService {
        let settings = SettingsStore(defaults: .ephemeral())
        settings.providerID = provider.id
        configure(settings)
        return TranscriptionService(
            registry: ProviderRegistry(providers: [provider]),
            keyStore: InMemoryAPIKeyStore(keys: keys),
            settings: settings,
            environment: environment
        )
    }

    @Test func missingKeyEverywhereThrowsTyped() async {
        let service = makeService(provider: .returning("unused"))

        do {
            _ = try await service.transcribe(audioFileURL: audioURL)
            Issue.record("Expected missingAPIKey")
        } catch let error as AppError {
            #expect(error == .missingAPIKey)
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    @Test func usesSettingsModelAndLanguage() async throws {
        let captured = CapturedConfiguration()
        let service = makeService(provider: captured.provider(), keys: ["mock": "sk-from-keychain"]) { settings in
            settings.model = "mock-advanced"
            settings.languageCode = "en"
        }

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value?.apiKey == "sk-from-keychain")
        #expect(captured.value?.model == "mock-advanced")
        #expect(captured.value?.language == "en")
    }

    @Test func staleModelFallsBackToProviderDefault() async throws {
        let captured = CapturedConfiguration()
        let service = makeService(provider: captured.provider(), keys: ["mock": "sk-test"]) { settings in
            settings.model = "model-that-no-longer-exists"
        }

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value?.model == "mock-default")
    }

    @Test func unknownProviderIDFallsBackToRegistryDefault() async throws {
        let captured = CapturedConfiguration()
        let service = makeService(provider: captured.provider(), keys: ["mock": "sk-test"]) { settings in
            settings.providerID = "provider-that-was-uninstalled"
        }

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value != nil)
    }

    @Test func environmentOverrideWinsForOpenAI() async throws {
        let captured = CapturedConfiguration()
        let openAILikeProvider = MockTranscriptionProvider(id: "openai", handler: captured.handler())
        let service = makeService(
            provider: openAILikeProvider,
            keys: ["openai": "sk-from-keychain"],
            environment: ["OPENDICTATION_OPENAI_API_KEY": "sk-from-env"]
        )

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value?.apiKey == "sk-from-env")
    }

    @Test func environmentOverrideIgnoredForOtherProviders() async throws {
        let captured = CapturedConfiguration()
        let service = makeService(
            provider: captured.provider(),
            keys: ["mock": "sk-from-keychain"],
            environment: ["OPENDICTATION_OPENAI_API_KEY": "sk-from-env"]
        )

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value?.apiKey == "sk-from-keychain")
    }
}

/// Captures the configuration a provider was called with.
/// Serialized test access only, hence the unchecked Sendable.
private final class CapturedConfiguration: @unchecked Sendable {
    var value: TranscriptionConfiguration?

    func handler() -> @Sendable (URL, TranscriptionConfiguration) throws -> Transcript {
        { _, configuration in
            self.value = configuration
            return Transcript(text: "ok", duration: 1, providerID: "mock", model: configuration.model, createdAt: .now)
        }
    }

    func provider() -> MockTranscriptionProvider {
        MockTranscriptionProvider(handler: handler())
    }
}
