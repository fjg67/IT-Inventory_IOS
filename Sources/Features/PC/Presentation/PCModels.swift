import Foundation

enum PCStatus: String, CaseIterable, Sendable {
    case hot = "A chaud"
    case rework = "A reusiner"
    case machining = "En usinage"
    case available = "Disponible"
    case sent = "Envoye"
    case unknown = "Inconnu"

    var descriptionValue: String {
        switch self {
        case .hot: return "Statut: A chaud"
        case .rework: return "Statut: A reusiner"
        case .machining: return "Statut: En usinage"
        case .available: return "Statut: Disponible"
        case .sent: return "Statut: Envoye"
        case .unknown: return "Statut: Inconnu"
        }
    }

    var familyValue: String {
        switch self {
        case .available: return "PC disponible"
        case .hot, .rework, .machining, .sent, .unknown: return "PC portable"
        }
    }

    static func from(description: String?) -> PCStatus {
        let text = (description ?? "")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        if text.contains("a chaud") { return .hot }
        if text.contains("a reusiner") { return .rework }
        if text.contains("en usinage") { return .machining }
        if text.contains("disponible") { return .available }
        if text.contains("envoye") { return .sent }
        return .unknown
    }
}

enum PCHeaderFilter: CaseIterable, Sendable {
    case hot
    case rework
    case machining
    case available
    case sent

    var title: String {
        switch self {
        case .hot: return "A chaud"
        case .rework: return "A reusiner"
        case .machining: return "En usinage"
        case .available: return "Disponible"
        case .sent: return "Envoye"
        }
    }
}

struct PCSentHistoryRecord: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let articleID: UUID
    let hostname: String
    let model: String
    let destinationAgency: String
    let recipientName: String
    let sentAt: Date
    let technicianName: String
}

struct PCCreateDraft: Sendable {
    var hostname: String = ""
    var assetNumber: String = ""
    var status: PCStatus = .hot
    var parcType: String = "Portable siege"
    var brand: String = "DELL"
    var model: String = ""
}
