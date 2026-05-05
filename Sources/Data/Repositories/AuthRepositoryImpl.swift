import Foundation

struct AuthRepositoryImpl: AuthRepository {
    private let remote: any AuthRemoteDataSource
    private let secureStore: any SecureSessionStore

    init(remote: any AuthRemoteDataSource, secureStore: any SecureSessionStore) {
        self.remote = remote
        self.secureStore = secureStore
    }

    func restoreSession() async throws -> AuthSession? {
        if let cached = try secureStore.load(), cached.expiresAt > Date() {
            return cached
        }

        if let remoteSession = try await remote.currentSession() {
            try secureStore.save(remoteSession)
            return remoteSession
        }

        try secureStore.clear()
        return nil
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        do {
            let session = try await remote.signIn(email: email, password: password)
            try secureStore.save(session)
            return session
        } catch {
            throw AuthErrorMapper.map(error)
        }
    }

    func signOut() async throws {
        do {
            try await remote.signOut()
        } catch {
            throw AuthErrorMapper.map(error)
        }

        try secureStore.clear()
    }
}
