import SwiftUI

struct XXLScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 22, weight: .semibold))
                Text("Scanner")
                    .font(.title3.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .foregroundStyle(AppColor.textPrimary)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [AppColor.brand, AppColor.brandDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    // inner highlight
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.clear],
                        startPoint: .top, endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: AppColor.brand.opacity(0.55), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ouvrir le scanner")
    }
}
