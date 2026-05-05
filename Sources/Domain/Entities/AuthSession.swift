import Foundation

struct AuthSession: Equatable, Sendable {
    let userID: String
    let email: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
