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

        try keychain.save("sk-updated", for: providerID)
        #expect(try keychain.key(for: providerID) == "sk-updated")

        try keychain.deleteKey(for: providerID)
        #expect(try keychain.key(for: providerID) == nil)
    }

    @Test func deletingAMissingKeyIsNotAnError() throws {
        let keychain = KeychainService()

        try keychain.deleteKey(for: "test-never-existed-\(UUID().uuidString)")
    }
}
