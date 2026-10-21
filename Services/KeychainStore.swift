import Foundation
import Security

struct PersistedSession: Codable, Equatable, Sendable {
    var uid: String
    var email: String
    var idToken: String
    var refreshToken: String
    var expiration: Date
    var usesCloud: Bool
}

struct LocalCredential: Codable, Equatable, Sendable {
    var email: String
    var uid: String
    var salt: String
    var passwordHash: String
}

enum KeychainStore {
    private static let service = "com.pinkmoney.session"

    static func set(_ data: Data, account: String) throws {
        let query = base(account: account)
        SecItemDelete(query as CFDictionary)

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(insert as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PinkMoneyError.message("No se pudo guardar la sesión en el llavero (\(status)).")
        }
    }

    static func data(account: String) -> Data? {
        var query = base(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(account: String) {
        SecItemDelete(base(account: account) as CFDictionary)
    }

    private static func base(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum SessionVault {
    private static let sessionAccount = "session"
    private static let credentialsAccount = "local-credentials"

    static func loadSession() -> PersistedSession? {
        guard let data = KeychainStore.data(account: sessionAccount) else { return nil }
        return try? JSONDecoder().decode(PersistedSession.self, from: data)
    }

    static func saveSession(_ session: PersistedSession) throws {
        let data = try JSONEncoder().encode(session)
        try KeychainStore.set(data, account: sessionAccount)
    }

    static func deleteSession() {
        KeychainStore.delete(account: sessionAccount)
    }

    static func credentials() -> [LocalCredential] {
        guard let data = KeychainStore.data(account: credentialsAccount),
              let stored = try? JSONDecoder().decode([LocalCredential].self, from: data) else {
            return []
        }
        return stored
    }

    static func credential(email: String) -> LocalCredential? {
        credentials().first { $0.email == email }
    }

    static func saveCredential(_ credential: LocalCredential) throws {
        var stored = credentials().filter { $0.email != credential.email }
        stored.append(credential)
        let data = try JSONEncoder().encode(stored)
        try KeychainStore.set(data, account: credentialsAccount)
    }
}
