import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(AppColor.card)
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.4))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04),
                                AppColor.brand.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: AppColor.brand.opacity(0.08), radius: 24, x: 0, y: 8)
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 4)
    }
}
