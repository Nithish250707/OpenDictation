import Foundation

/// Decorator that caches API keys in memory after the first successful
/// Keychain lookup, so the app performs at most one protected read per
/// provider per launch.
///
/// Why this exists: with development (ad-hoc) signing, every rebuild changes
/// the app's code signature, the keychain item's ACL no longer matches, and
/// macOS prompts on *each* protected read. The app used to read on every
/// menu open and every transcription — multiplying those prompts.
///
/// Security posture is unchanged: the key already passes through process
/// memory on every request; this cache is process-local, never persisted,
/// invalidated by save/delete, and gone when the app quits. Failed lookups
/// are never cached.
final class CachedAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private let underlying: any APIKeyStoring
    private let lock = NSLock()
    private var cachedKeys: [String: String] = [:]
    private var knownPresent: Set<String> = []
    private var knownAbsent: Set<String> = []

    init(wrapping underlying: any APIKeyStoring) {
        self.underlying = underlying
    }

    func key(for providerID: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedKeys[providerID] { return cached }
        if knownAbsent.contains(providerID) { return nil }

        // Errors propagate uncached so a transient failure can be retried.
        let value = try underlying.key(for: providerID)
        if let value {
            cachedKeys[providerID] = value
            knownPresent.insert(providerID)
        } else {
            knownAbsent.insert(providerID)
        }
        return value
    }

    func hasKey(for providerID: String) -> Bool {
        lock.lock()
        if cachedKeys[providerID] != nil || knownPresent.contains(providerID) {
            lock.unlock()
            return true
        }
        if knownAbsent.contains(providerID) {
            lock.unlock()
            return false
        }
        lock.unlock()

        // Prompt-free attributes-only check (see KeychainService.hasKey);
        // only *presence* is cached here — the secret itself is fetched
        // lazily by the first real use.
        let present = underlying.hasKey(for: providerID)
        lock.lock()
        defer { lock.unlock() }
        if present {
            knownPresent.insert(providerID)
        } else {
            knownAbsent.insert(providerID)
        }
        return present
    }

    func save(_ key: String, for providerID: String) throws {
        try underlying.save(key, for: providerID)
        lock.lock()
        defer { lock.unlock() }
        cachedKeys[providerID] = key
        knownPresent.insert(providerID)
        knownAbsent.remove(providerID)
    }

    func deleteKey(for providerID: String) throws {
        try underlying.deleteKey(for: providerID)
        lock.lock()
        defer { lock.unlock() }
        cachedKeys.removeValue(forKey: providerID)
        knownPresent.remove(providerID)
        knownAbsent.insert(providerID)
    }
}
