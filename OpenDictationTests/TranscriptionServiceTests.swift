import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct TranscriptionServiceTests {
    private let audioURL = URL(fileURLWithPath: "/dev/null")

    @Test func missingKeyEverywhereThrowsTyped() async {
        let service = TranscriptionService(
            provider: MockTranscriptionProvider.returning("unused"),
            keyStore: InMemoryAPIKeyStore(),
            environment: [:]
        )

        do {
            _ = try await service.transcribe(audioFileURL: audioURL)
            Issue.record("Expected missingAPIKey")
        } catch let error as AppError {
            #expect(error == .missingAPIKey)
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    @Test func keychainKeyIsUsed() async throws {
        let captured = CapturedConfiguration()
        let service = TranscriptionService(
            provider: captured.provider(),
            keyStore: InMemoryAPIKeyStore(keys: ["mock": "sk-from-keychain"]),
            environment: [:]
        )

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value?.apiKey == "sk-from-keychain")
        #expect(captured.value?.model == OpenAITranscriptionProvider.defaultModel)
    }

    @Test func environmentOverrideWinsOverKeychain() async throws {
        let captured = CapturedConfiguration()
        let service = TranscriptionService(
            provider: captured.provider(),
            keyStore: InMemoryAPIKeyStore(keys: ["mock": "sk-from-keychain"]),
            environment: ["OPENDICTATION_OPENAI_API_KEY": "sk-from-env"]
        )

        _ = try await service.transcribe(audioFileURL: audioURL)

        #expect(captured.value?.apiKey == "sk-from-env")
    }
}

/// Captures the configuration a provider was called with.
/// Serialized test access only, hence the unchecked Sendable.
private final class CapturedConfiguration: @unchecked Sendable {
    var value: TranscriptionConfiguration?

    func provider() -> MockTranscriptionProvider {
        MockTranscriptionProvider { _, configuration in
            self.value = configuration
            return Transcript(text: "ok", duration: 1, providerID: "mock", model: configuration.model, createdAt: .now)
        }
    }
}
