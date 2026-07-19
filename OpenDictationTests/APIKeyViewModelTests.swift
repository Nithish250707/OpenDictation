import Testing
@testable import OpenDictation

@MainActor
struct APIKeyViewModelTests {
    @Test func reflectsExistingKeyOnLaunch() {
        let store = InMemoryAPIKeyStore(keys: ["openai": "sk-existing"])

        let viewModel = APIKeyViewModel(keyStore: store, providerID: "openai")

        #expect(viewModel.hasKey)
    }

    @Test func savesTrimmedValidKey() throws {
        let store = InMemoryAPIKeyStore()
        let viewModel = APIKeyViewModel(keyStore: store, providerID: "openai")

        viewModel.beginEditing()
        viewModel.draft = "  sk-a-perfectly-plausible-key  "
        viewModel.save()

        #expect(viewModel.hasKey)
        #expect(!viewModel.isEditing)
        #expect(viewModel.errorMessage == nil)
        // The draft must not linger in memory after saving.
        #expect(viewModel.draft.isEmpty)
        #expect(try store.key(for: "openai") == "sk-a-perfectly-plausible-key")
    }

    @Test func rejectsEmptyDraft() {
        let viewModel = APIKeyViewModel(keyStore: InMemoryAPIKeyStore(), providerID: "openai")

        viewModel.beginEditing()
        viewModel.draft = "   "
        viewModel.save()

        #expect(!viewModel.hasKey)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isEditing)
    }

    @Test func rejectsKeysContainingSpaces() {
        let viewModel = APIKeyViewModel(keyStore: InMemoryAPIKeyStore(), providerID: "openai")

        viewModel.beginEditing()
        viewModel.draft = "sk-something with-spaces"
        viewModel.save()

        #expect(!viewModel.hasKey)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func rejectsImplausiblyShortKeys() {
        let viewModel = APIKeyViewModel(keyStore: InMemoryAPIKeyStore(), providerID: "openai")

        viewModel.beginEditing()
        viewModel.draft = "sk-tiny"
        viewModel.save()

        #expect(!viewModel.hasKey)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func removeDeletesFromStore() throws {
        let store = InMemoryAPIKeyStore(keys: ["openai": "sk-existing"])
        let viewModel = APIKeyViewModel(keyStore: store, providerID: "openai")

        viewModel.removeKey()

        #expect(!viewModel.hasKey)
        #expect(try store.key(for: "openai") == nil)
    }

    @Test func switchingProviderReloadsPresence() {
        let store = InMemoryAPIKeyStore(keys: ["openai": "sk-existing"])
        let viewModel = APIKeyViewModel(keyStore: store, providerID: "openai")

        viewModel.providerChanged(to: "groq")

        #expect(!viewModel.hasKey)

        viewModel.providerChanged(to: "openai")
        #expect(viewModel.hasKey)
    }
}
