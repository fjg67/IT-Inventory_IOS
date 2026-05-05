import Foundation

struct Site: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let isActive: Bool
    let parentSiteId: String?
}
