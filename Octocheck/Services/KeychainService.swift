import Foundation
import Security

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .loadFailed:
            return "Failed to load from Keychain"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: Constants.Keychain.account,
        ]
    }

    func savePAT(_ token: String) throws {
        guard let data = token.data(using: .utf8) else { return }

        // Delete existing item first
        SecItemDelete(baseQuery as CFDictionary)

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func loadPAT() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return token
    }

    func deletePAT() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
