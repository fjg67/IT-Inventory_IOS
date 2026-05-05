import SwiftUI

struct RecentMovementItem: Identifiable {
    let id: String
    let type: MovementType
    let quantity: Int
    let articleName: String
    let articleReference: String
    let createdAt: Date

    var typeLabel: String { type.label }

    var typeColor: Color {
        switch type {
        case .entry: return .green
        case .exit: return Color(red: 1, green: 0.35, blue: 0.35)
        case .transfer: return Color(red: 0.3, green: 0.6, blue: 1)
        case .adjustment: return Color(red: 1, green: 0.7, blue: 0.2)
        case .unknown: return .gray
        }
    }

    var typeIcon: String {
        switch type {
        case .entry: return "arrow.down.circle.fill"
        case .exit: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
