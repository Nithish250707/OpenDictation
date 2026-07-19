import Foundation
import Security

/// Generic-password Keychain storage, one item per provider
/// (service = app identifier, account = provider ID).
struct KeychainService: APIKeyStoring {
    enum KeychainError: Error {
        case unexpectedStatus(OSStatus)
    }

    private static let service = "org.opendictation.OpenDictation"

    func save(_ key: String, for providerID: String) throws {
        let data = Data(key.utf8)

        if try self.key(for: providerID) != nil {
            let update: [String: Any] = [kSecValueData as String: data]
            let status = SecItemUpdate(baseQuery(for: providerID) as CFDictionary, update as CFDictionary)
            guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        } else {
            var attributes = baseQuery(for: providerID)
            attributes[kSecValueData as String] = data
            let status = SecItemAdd(attributes as CFDictionary, nil)
            guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        }
    }

    func key(for providerID: String) throws -> String? {
        var query = baseQuery(for: providerID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            return String(decoding: data, as: UTF8.self)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func deleteKey(for providerID: String) throws {
        let status = SecItemDelete(baseQuery(for: providerID) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func baseQuery(for providerID: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: providerID,
        ]
    }
}
