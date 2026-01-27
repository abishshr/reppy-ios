import Foundation
import Security

/// Service for secure keychain storage
final class KeychainService {
    private let service = "com.reppy.app"

    // MARK: - Token Management

    func saveToken(_ token: String) {
        save(key: Constants.Keychain.accessToken, value: token)
    }

    func getToken() -> String? {
        get(key: Constants.Keychain.accessToken)
    }

    func deleteToken() {
        delete(key: Constants.Keychain.accessToken)
    }

    // MARK: - User ID

    func saveUserId(_ userId: String) {
        save(key: Constants.Keychain.userId, value: userId)
    }

    func getUserId() -> String? {
        get(key: Constants.Keychain.userId)
    }

    // MARK: - Generic Operations

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    func clearAll() {
        deleteToken()
        delete(key: Constants.Keychain.userId)
    }
}
