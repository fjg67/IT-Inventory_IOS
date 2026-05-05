import Foundation
import UserNotifications

protocol StockMovementNotificationService {
    func notifyMovement(
        type: MovementType,
        quantity: Int,
        articleName: String,
        siteSourceName: String?,
        siteDestinationName: String?,
        technicianName: String
    )
}

final class LocalStockMovementNotificationService: StockMovementNotificationService {
    private let center = UNUserNotificationCenter.current()

    init() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notifyMovement(
        type: MovementType,
        quantity: Int,
        articleName: String,
        siteSourceName: String?,
        siteDestinationName: String?,
        technicianName: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Mouvement enregistre"
        content.subtitle = "\(movementSymbol(for: type)) \(movementTag(for: type))  ·  Qte: \(quantity)"

        let locationText: String
        switch type {
        case .entry:
            locationText = siteDestinationName ?? "Site inconnu"
        case .exit, .adjustment:
            locationText = siteSourceName ?? "Site inconnu"
        case .transfer:
            let from = siteSourceName ?? "Site inconnu"
            let to = siteDestinationName ?? "Site inconnu"
            locationText = "\(from) -> \(to)"
        case .unknown:
            locationText = siteSourceName ?? siteDestinationName ?? "Site inconnu"
        }

        content.body = "Article: \(articleName)\nLieu stock: \(locationText)\nTechnicien: \(technicianName)"
        content.threadIdentifier = "stock-movements"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "stock-movement-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private func movementTag(for type: MovementType) -> String {
        switch type {
        case .entry:
            return "ENTREE"
        case .exit:
            return "SORTIE"
        case .adjustment:
            return "AJUSTEMENT"
        case .transfer:
            return "TRANSFERT"
        case .unknown:
            return "MOUVEMENT"
        }
    }

    private func movementSymbol(for type: MovementType) -> String {
        switch type {
        case .entry:
            return "⬇︎"
        case .exit:
            return "⬆︎"
        case .adjustment:
            return "⚙︎"
        case .transfer:
            return "⇄"
        case .unknown:
            return "•"
        }
    }
}
