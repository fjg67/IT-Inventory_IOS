// MovementRowView.swift
import SwiftUI

struct MovementRowView: View {
    let item: HomeMovementItem
    let appear: Bool
    let delay: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.typeColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .shadow(color: item.typeColor.opacity(0.45), radius: 10, x: 0, y: 0)

                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.typeColor)
                    .accessibilityLabel("Type mouvement \(item.typeLabel)")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.articleName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(OpsCrystal.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.typeLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(item.typeColor)
                    Text("·")
                        .foregroundStyle(OpsCrystal.textSecondary)
                    Text(item.code)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(OpsCrystal.textSecondary)
                    Text("·")
                        .foregroundStyle(OpsCrystal.textSecondary)
                    Text(item.technicianAcronym)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(OpsCrystal.accentSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.delta > 0 ? "+\(item.delta)" : "\(item.delta)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(item.delta > 0 ? OpsCrystal.positive : OpsCrystal.negative)
                    .monospacedDigit()

                Text(item.ageLabel)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(OpsCrystal.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .offset(x: appear ? 0 : -20)
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(delay), value: appear)
    }
}
