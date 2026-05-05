import Foundation

protocol AuthRepository: Sendable {
    func restoreSession() async throws -> AuthSession?
    func signIn(email: String, password: String) async throws -> AuthSession
    func signOut() async throws
}
