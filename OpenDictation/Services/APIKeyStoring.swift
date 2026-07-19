import Foundation

/// Capability: durable, secure storage for provider API keys.
/// Keys live only in the Apple Keychain — never UserDefaults, files, or logs.
protocol APIKeyStoring: Sendable {
    func save(_ key: String, for providerID: String) throws
    func key(for providerID: String) throws -> String?
    func deleteKey(for providerID: String) throws

    /// Presence check for UI — avoids handing the key material itself around.
    /// A protocol requirement (not just an extension) so implementations can
    /// answer it without reading the protected secret at all.
    func hasKey(for providerID: String) -> Bool
}

extension APIKeyStoring {
    func hasKey(for providerID: String) -> Bool {
        (try? key(for: providerID)) != nil
    }
}
