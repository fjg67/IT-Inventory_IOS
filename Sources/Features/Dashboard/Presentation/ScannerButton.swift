// ScannerButton.swift
import SwiftUI
import UIKit

struct ScannerButton: View {
    let action: () -> Void

    @State private var glowPulse = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            ZStack {
                // Glow halo
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: 0x6C5CE7).opacity(0.35))
                    .blur(radius: glowPulse ? 18 : 12)
                    .scaleEffect(glowPulse ? 1.04 : 0.98)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)

                // Main pill
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x7B6CF6), Color(hex: 0x5E4ED4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("Scanner un code-barres")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
        }
        .buttonStyle(.plain)
        .onAppear { glowPulse = true }
    }
}
