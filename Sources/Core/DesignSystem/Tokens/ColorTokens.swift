import SwiftUI

enum AppColor {
    // MARK: – Brand (same in both modes)
    static let brand      = Color(red: 0.55, green: 0.33, blue: 1.00)
    static let brandDeep  = Color(red: 0.32, green: 0.18, blue: 0.85)
    static let accent     = Color(red: 0.08, green: 0.82, blue: 1.00)
    static let accentDeep = Color(red: 0.04, green: 0.58, blue: 0.90)

    // MARK: – Status (same in both modes)
    static let success = Color(red: 0.18, green: 0.92, blue: 0.54)
    static let warning = Color(red: 1.00, green: 0.72, blue: 0.10)
    static let danger  = Color(red: 1.00, green: 0.30, blue: 0.38)

    // MARK: – Adaptive Backgrounds
    static let page = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.047, green: 0.047, blue: 0.118, alpha: 1)
            : UIColor(red: 0.955, green: 0.955, blue: 0.975, alpha: 1)
    }))

    static let surface = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.09, blue: 0.19, alpha: 1)
            : UIColor(red: 0.90, green: 0.90, blue: 0.95, alpha: 1)
    }))

    static let card = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.12, blue: 0.24, alpha: 1)
            : UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1)
    }))

    // MARK: – Adaptive Text
    static let textPrimary = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 0.07, green: 0.07, blue: 0.15, alpha: 1)
    }))

    static let textSecondary = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.55)
            : UIColor(red: 0.28, green: 0.28, blue: 0.38, alpha: 1)
    }))

    static let textTertiary = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.30)
            : UIColor(red: 0.52, green: 0.52, blue: 0.62, alpha: 1)
    }))

    // MARK: – Adaptive separator
    static let separator = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.08)
            : UIColor(white: 0, alpha: 0.08)
    }))

    // MARK: – Gradients
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [brand, brandDeep],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private static let pageGradientTop = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.07, blue: 0.22, alpha: 1)
            : UIColor(red: 0.92, green: 0.90, blue: 0.98, alpha: 1)
    }))

    static var pageGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: pageGradientTop, location: 0),
                .init(color: page, location: 0.5),
                .init(color: page, location: 1)
            ],
            startPoint: .top, endPoint: .bottom)
    }

    static func statusColor(for type: String) -> Color {
        switch type {
        case "entry":      return success
        case "exit":       return danger
        case "adjustment": return warning
        case "transfer":   return accent
        default:           return textSecondary
        }
    }
}

// MARK: – AppTheme

enum AppTheme: String, CaseIterable {
    case system, dark, light

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }

    var label: String {
        switch self {
        case .system: return "Automatique"
        case .dark:   return "Sombre"
        case .light:  return "Clair"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .dark:   return "moon.fill"
        case .light:  return "sun.max.fill"
        }
    }
}
