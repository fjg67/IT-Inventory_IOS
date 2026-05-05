import Foundation

protocol SecureSessionStore: Sendable {
    func save(_ session: AuthSession) throws
    func load() throws -> AuthSession?
    func clear() throws
}

struct KeychainSecureSessionStore: SecureSessionStore {
    private let keychain: any KeychainClient
    private let key = "auth.session"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(keychain: any KeychainClient) {
        self.keychain = keychain
    }

    func save(_ session: AuthSession) throws {
        let stored = StoredAuthSession(
            userID: session.userID,
            email: session.email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: session.expiresAt
        )
        let data = try encoder.encode(stored)
        try keychain.set(data, for: key)
    }

    func load() throws -> AuthSession? {
        guard let data = try keychain.get(for: key) else {
            return nil
        }

        let stored = try decoder.decode(StoredAuthSession.self, from: data)
        return AuthSession(
            userID: stored.userID,
            email: stored.email,
            accessToken: stored.accessToken,
            refreshToken: stored.refreshToken,
            expiresAt: stored.expiresAt
        )
    }

    func clear() throws {
        try keychain.delete(for: key)
    }
}

private struct StoredAuthSession: Codable {
    let userID: String
    let email: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
