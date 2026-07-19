import Foundation
import Testing
@testable import OpenDictation

struct CachedAPIKeyStoreTests {
    @Test func secondReadIsServedFromCache() throws {
        let counting = CountingAPIKeyStore(keys: ["openai": "sk-cached"])
        let store = CachedAPIKeyStore(wrapping: counting)

        #expect(try store.key(for: "openai") == "sk-cached")
        #expect(try store.key(for: "openai") == "sk-cached")
        #expect(try store.key(for: "openai") == "sk-cached")

        #expect(counting.keyReads == 1)
    }

    @Test func absenceIsCachedToo() throws {
        let counting = CountingAPIKeyStore()
        let store = CachedAPIKeyStore(wrapping: counting)

        #expect(try store.key(for: "openai") == nil)
        #expect(try store.key(for: "openai") == nil)

        #expect(counting.keyReads == 1)
    }

    @Test func presenceChecksNeverReadTheSecret() {
        let counting = CountingAPIKeyStore(keys: ["openai": "sk-secret"])
        let store = CachedAPIKeyStore(wrapping: counting)

        #expect(store.hasKey(for: "openai"))
        #expect(store.hasKey(for: "openai"))

        #expect(counting.keyReads == 0)
        #expect(counting.presenceChecks == 1)
    }

    @Test func saveUpdatesCacheWithoutARead() throws {
        let counting = CountingAPIKeyStore()
        let store = CachedAPIKeyStore(wrapping: counting)

        try store.save("sk-new", for: "openai")

        #expect(try store.key(for: "openai") == "sk-new")
        #expect(store.hasKey(for: "openai"))
        #expect(counting.keyReads == 0)
        #expect(counting.presenceChecks == 0)
    }

    @Test func deleteInvalidatesTheCache() throws {
        let counting = CountingAPIKeyStore(keys: ["openai": "sk-doomed"])
        let store = CachedAPIKeyStore(wrapping: counting)
        _ = try store.key(for: "openai")

        try store.deleteKey(for: "openai")

        #expect(try store.key(for: "openai") == nil)
        #expect(!store.hasKey(for: "openai"))
        // The post-delete absence is answered from the cache.
        #expect(counting.keyReads == 1)
    }

    @Test func errorsAreNeverCached() {
        let counting = CountingAPIKeyStore(keys: ["openai": "sk-eventually"])
        counting.nextReadError = KeychainService.KeychainError.unexpectedStatus(-25308)
        let store = CachedAPIKeyStore(wrapping: counting)

        #expect(throws: KeychainService.KeychainError.self) {
            try store.key(for: "openai")
        }
        // The failure wasn't cached; the retry reaches the underlying store.
        #expect(try! store.key(for: "openai") == "sk-eventually")
        #expect(counting.keyReads == 2)
    }
}

/// Underlying store that counts protected reads vs. presence checks.
/// Serialized test access only, hence the unchecked Sendable.
private final class CountingAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private var keys: [String: String]
    private(set) var keyReads = 0
    private(set) var presenceChecks = 0
    var nextReadError: Error?

    init(keys: [String: String] = [:]) {
        self.keys = keys
    }

    func key(for providerID: String) throws -> String? {
        // A failed attempt still counts as a read reaching the store.
        keyReads += 1
        if let nextReadError {
            self.nextReadError = nil
            throw nextReadError
        }
        return keys[providerID]
    }

    func hasKey(for providerID: String) -> Bool {
        presenceChecks += 1
        return keys[providerID] != nil
    }

    func save(_ key: String, for providerID: String) throws { keys[providerID] = key }
    func deleteKey(for providerID: String) throws { keys[providerID] = nil }
}
