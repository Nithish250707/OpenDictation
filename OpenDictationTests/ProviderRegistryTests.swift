import Testing
@testable import OpenDictation

struct ProviderRegistryTests {
    private let registry = ProviderRegistry(providers: [
        MockTranscriptionProvider(id: "alpha") { _, _ in fatalError("unused") },
        MockTranscriptionProvider(id: "beta") { _, _ in fatalError("unused") },
    ])

    @Test func looksUpProviderByID() {
        #expect(registry.provider(id: "beta")?.id == "beta")
    }

    @Test func unknownIDReturnsNil() {
        #expect(registry.provider(id: "gamma") == nil)
    }

    @Test func defaultIsFirstRegistered() {
        #expect(registry.default.id == "alpha")
    }

    @Test func liveRegistryContainsOpenAI() {
        #expect(ProviderRegistry.live().provider(id: "openai") != nil)
    }
}
