import Foundation
import Testing
@testable import OpenDictation

/// Exercises the real Keychain (test host app context) with a unique,
/// always-cleaned-up account per test run.
struct KeychainServiceTests {
    @Test func saveReadUpdateDeleteRoundTrip() throws {
        let keychain = KeychainService()
        let providerID = "test-\(UUID().uuidString)"
        defer { try? keychain.deleteKey(for: providerID) }

        #expect(try keychain.key(for: providerID) == nil)

        try keychain.save("sk-first", for: providerID)
        #expect(try keychain.key(for: providerID) == "sk-first")
        // Attributes-only presence check agrees with the protected read.
        #expect(keychain.hasKey(for: providerID))

        try keychain.save("sk-updated", for: providerID)
        #expect(try keychain.key(for: providerID) == "sk-updated")

        try keychain.deleteKey(for: providerID)
        #expect(try keychain.key(for: providerID) == nil)
    }

    @Test func deletingAMissingKeyIsNotAnError() throws {
        let keychain = KeychainService()

        try keychain.deleteKey(for: "test-never-existed-\(UUID().uuidString)")
    }

    /// Saving must work (and replace) without ever reading the stored secret,
    /// so it can't trigger a Keychain prompt.
    @Test func savingReplacesWithoutReadingFirst() throws {
        let keychain = KeychainService()
        let providerID = "test-\(UUID().uuidString)"
        defer { try? keychain.deleteKey(for: providerID) }

        // Create, then replace — never calling key() before either save.
        try keychain.save("sk-original", for: providerID)
        try keychain.save("sk-replacement", for: providerID)

        #expect(keychain.hasKey(for: providerID))
        #expect(try keychain.key(for: providerID) == "sk-replacement")
    }
}
