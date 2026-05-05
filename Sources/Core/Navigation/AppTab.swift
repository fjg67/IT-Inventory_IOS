import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case articles
    case scan
    case pc
    case movements
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Accueil"
        case .articles: return "Articles"
        case .scan: return "Scan"
        case .pc: return "PC"
        case .movements: return "Mouvements"
        case .settings: return "Reglages"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .articles: return "shippingbox"
        case .scan: return "barcode.viewfinder"
        case .pc: return "desktopcomputer"
        case .movements: return "arrow.left.arrow.right"
        case .settings: return "gearshape"
        }
    }
}
