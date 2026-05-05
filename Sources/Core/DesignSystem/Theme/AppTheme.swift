import SwiftUI

struct AppThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(AppColor.brand)
    }
}

extension View {
    func applyAppTheme() -> some View {
        modifier(AppThemeModifier())
    }
}
