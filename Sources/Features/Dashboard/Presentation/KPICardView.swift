// KPICardView.swift
import SwiftUI

struct KPICardView: View {
    let item: HomeKPI
    let appear: Bool
    let delay: Double

    @State private var pulse = false

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(item.gradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: item.tint.opacity(0.55), radius: 14, x: 0, y: 6)
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColor.textPrimary)
                            .accessibilityLabel("Icone KPI \(item.title)")
                    }

                if item.showsPulseBadge {
                    Circle()
                        .fill(Color(hex: 0xFF6B6B))
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle()
                                .stroke(Color(hex: 0xFF6B6B).opacity(0.35), lineWidth: 9)
                                .scaleEffect(pulse ? 1.9 : 0.4)
                                .opacity(pulse ? 0 : 0.8)
                        }
                        .offset(x: 5, y: -5)
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                                pulse = true
                            }
                        }
                }
            }

            VStack(spacing: 5) {
                Text(item.value)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(OpsCrystal.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(item.title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(OpsCrystal.textSecondary)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .offset(y: appear ? 0 : 20)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.52, dampingFraction: 0.78).delay(delay), value: appear)
        .animation(.default, value: item.value)
    }
}
