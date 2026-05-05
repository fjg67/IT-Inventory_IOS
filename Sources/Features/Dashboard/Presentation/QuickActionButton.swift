// QuickActionButton.swift
import SwiftUI
import UIKit

private struct ParticleBurstView: View {
    let trigger: Int
    let color: Color

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(color.opacity(0.65))
                    .frame(width: 5, height: 5)
                    .offset(y: animate ? -34 : 0)
                    .rotationEffect(.degrees(Double(index) * 60))
                    .opacity(animate ? 0 : 0.9)
            }
        }
        .onChange(of: trigger) { _, _ in
            animate = false
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
    }
}

struct QuickActionButton: View {
    let action: HomeQuickAction
    let onTap: () -> Void

    @State private var burstTrigger = 0

    var body: some View {
        Button {
            burstTrigger += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(action.color.opacity(0.20))
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(action.color.opacity(0.25), lineWidth: 1)
                        }
                    Image(systemName: action.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(action.color)
                        .accessibilityLabel("Action \(action.title)")
                    ParticleBurstView(trigger: burstTrigger, color: action.color)
                }

                Text(action.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(OpsCrystal.textPrimary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(action.color.opacity(0.07))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(action.color.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
