import Foundation

struct StockMovementDTO: Decodable {
    let id: String
    let type: String
    let quantity: Int
    let reason: String?
    let articleId: UUID
    let fromSiteId: String?
    let toSiteId: String?
    let userId: String
    let createdAt: String

    func toDomain() -> StockMovement {
        StockMovement(
            id: id,
            type: MovementType(rawValue: type) ?? .unknown,
            quantity: quantity,
            reason: reason,
            articleId: articleId,
            fromSiteId: fromSiteId,
            toSiteId: toSiteId,
            userId: userId,
            createdAt: DateParser.parse(createdAt) ?? .distantPast
        )
    }
}
