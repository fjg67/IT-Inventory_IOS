import Foundation

enum AppError: Error, Equatable {
    case networkUnavailable
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validation(message: String)
    case unknown
}
