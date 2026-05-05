import Foundation
import Supabase

protocol AuthRemoteDataSource: Sendable {
    func signIn(email: String, password: String) async throws -> AuthSession
    func currentSession() async throws -> AuthSession?
    func signOut() async throws
}

struct SupabaseAuthRemoteDataSource: AuthRemoteDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        let session = try await client.auth.signIn(email: email, password: password)
        return try mapSession(session)
    }

    func currentSession() async throws -> AuthSession? {
        guard let session = client.auth.currentSession else {
            return nil
        }

        return try mapSession(session)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    private func mapSession(_ session: Session) throws -> AuthSession {
        guard let email = session.user.email else {
            throw AppError.unknown
        }

        let expiresAt = Date(timeIntervalSince1970: session.expiresAt)

        return AuthSession(
            userID: session.user.id.uuidString,
            email: email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: expiresAt
        )
    }
}
