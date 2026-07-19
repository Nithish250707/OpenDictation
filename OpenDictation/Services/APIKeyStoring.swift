import Foundation

/// Capability: durable, secure storage for provider API keys.
/// Keys live only in the Apple Keychain — never UserDefaults, files, or logs.
protocol APIKeyStoring: Sendable {
    func save(_ key: String, for providerID: String) throws
    func key(for providerID: String) throws -> String?
    func deleteKey(for providerID: String) throws
}
