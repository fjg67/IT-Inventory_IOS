import Foundation

enum MovementType: String, Sendable, CaseIterable, Identifiable {
    case entry = "ENTRY"
    case exit = "EXIT"
    case adjustment = "ADJUSTMENT"
    case transfer = "TRANSFER"
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .entry: return "Entrée"
        case .exit: return "Sortie"
        case .adjustment: return "Ajustement"
        case .transfer: return "Transfert"
        case .unknown: return "Inconnu"
        }
    }
}

struct StockMovement: Identifiable, Equatable, Sendable {
    let id: String
    let type: MovementType
    let quantity: Int
    let reason: String?
    let articleId: UUID
    let fromSiteId: String?
    let toSiteId: String?
    let userId: String
    let createdAt: Date
}

struct NewStockMovement: Sendable {
    let type: MovementType
    let quantity: Int
    let reason: String?
    let articleId: UUID
    let fromSiteId: String?
    let toSiteId: String?
    let userId: String
}
