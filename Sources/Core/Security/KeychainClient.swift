import Foundation
import Security

protocol KeychainClient: Sendable {
    func set(_ data: Data, for key: String) throws
    func get(for key: String) throws -> Data?
    func delete(for key: String) throws
}

struct SystemKeychainClient: KeychainClient {
    private let service: String

    init(service: String = "com.florianjovegarcia.itinventory") {
        self.service = service
    }

    func set(_ data: Data, for key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let update: [CFString: Any] = [
            kSecValueData: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var create = query
            create[kSecValueData] = data
            create[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let createStatus = SecItemAdd(create as CFDictionary, nil)
            guard createStatus == errSecSuccess else {
                throw KeychainError.unhandled(status: createStatus)
            }
            return
        }

        guard updateStatus == errSecSuccess else {
            throw KeychainError.unhandled(status: updateStatus)
        }
    }

    func get(for key: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status: status)
        }

        return result as? Data
    }

    func delete(for key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status: status)
        }
    }
}

enum KeychainError: Error {
    case unhandled(status: OSStatus)
}
