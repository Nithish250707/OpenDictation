import Foundation
import Observation

/// State and intent for the API key section of Settings. The stored key is
/// never read back into the UI — only its presence is surfaced.
@MainActor
@Observable
final class APIKeyViewModel {
    private(set) var hasKey = false
    private(set) var isEditing = false
    private(set) var errorMessage: String?
    var draft = ""

    private let keyStore: any APIKeyStoring
    private var providerID: String

    init(keyStore: any APIKeyStoring, providerID: String) {
        self.keyStore = keyStore
        self.providerID = providerID
        hasKey = keyStore.hasKey(for: providerID)
    }

    /// Called when the user switches providers in Settings.
    func providerChanged(to newProviderID: String) {
        providerID = newProviderID
        hasKey = keyStore.hasKey(for: providerID)
        cancelEditing()
    }

    func beginEditing() {
        draft = ""
        errorMessage = nil
        isEditing = true
    }

    func cancelEditing() {
        draft = ""
        errorMessage = nil
        isEditing = false
    }

    func save() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter an API key first."
            return
        }
        guard trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            errorMessage = "API keys can't contain spaces."
            return
        }
        guard trimmed.count >= 12 else {
            errorMessage = "That looks too short to be an API key."
            return
        }

        do {
            try keyStore.save(trimmed, for: providerID)
            hasKey = true
            cancelEditing()
        } catch {
            errorMessage = "Couldn't save to the Keychain. Please try again."
            Log.app.error("Keychain save failed: \(error.localizedDescription)")
        }
        draft = ""
    }

    func removeKey() {
        do {
            try keyStore.deleteKey(for: providerID)
            hasKey = false
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't remove the key. Please try again."
            Log.app.error("Keychain delete failed: \(error.localizedDescription)")
        }
    }
}
