import Foundation

enum AuthErrorMapper {
    static func map(_ error: Error) -> AppError {
        let message = error.localizedDescription.lowercased()

        if message.contains("invalid login credentials") {
            return .validation(message: "Identifiants invalides")
        }

        if message.contains("network") || message.contains("internet") {
            return .networkUnavailable
        }

        if message.contains("unauthorized") || message.contains("jwt") {
            return .unauthorized
        }

        return .unknown
    }
}
