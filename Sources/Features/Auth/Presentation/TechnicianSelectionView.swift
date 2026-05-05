import SwiftUI

struct TechnicianSelectionView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: TechnicianSelectionViewModel
    @State private var orbs = false

    let site: Site
    let onBack: () -> Void

    init(viewModel: TechnicianSelectionViewModel, site: Site, onBack: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.site = site
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────
            AppColor.page.ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(AppColor.brand.opacity(0.20))
                    .blur(radius: 80)
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 100, y: -40 + (orbs ? 12 : -12))
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: orbs)

                Circle()
                    .fill(AppColor.accent.opacity(0.10))
                    .blur(radius: 70)
                    .frame(width: 240, height: 240)
                    .offset(x: -60, y: geo.size.height * 0.6 + (orbs ? -8 : 8))
                    .animation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true), value: orbs)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Back button ──────────────────────────────────────
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Retour")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(AppColor.brand)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

                Spacer()

                // ── Header ───────────────────────────────────────────
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accentGradient)
                            .frame(width: 64, height: 64)
                            .shadow(color: AppColor.accent.opacity(0.35), radius: 16, x: 0, y: 6)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("Qui es-tu ?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)

                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppColor.accent)
                        Text(site.name)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                Spacer().frame(height: 40)

                // ── Technicians list ─────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.isLoading {
                            VStack(spacing: 0) {
                                ForEach(0..<5, id: \.self) { i in
                                    ShimmerRow()
                                    if i < 4 {
                                        Divider()
                                            .padding(.leading, AppSpacing.md + 46 + 16)
                                    }
                                }
                            }
                            .background(AppColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .padding(.horizontal, AppSpacing.md)
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppColor.warning)
                                Text(error)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .multilineTextAlignment(.center)
                                Button("Réessayer") {
                                    Task { await viewModel.reload() }
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.brand)
                            }
                            .padding(.vertical, AppSpacing.xl)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.technicians.enumerated()), id: \.element.id) { index, tech in
                                    TechnicianCard(technician: tech) {
                                        container.selectedTechnician = tech
                                    }
                                    if index < viewModel.technicians.count - 1 {
                                        Divider()
                                            .padding(.leading, AppSpacing.md + 46 + 16)
                                    }
                                }
                            }
                            .background(AppColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                            )
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }

                // ── Sign out ─────────────────────────────────────────
                Button {
                    container.authViewModel.signOutButtonTapped()
                } label: {
                    Text("Se déconnecter")
                        .font(.footnote)
                        .foregroundStyle(AppColor.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .onAppear {
            orbs = true
            viewModel.loadTechnicians()
        }
    }
}

// MARK: – Technician card
private struct TechnicianCard: View {
    let technician: Technician
    let onSelect: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Avatar with initials
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColor.brand, AppColor.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 46, height: 46)
                    Text(technician.initials)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                // Role only
                RoleBadge(role: technician.displayRole)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 14)
            .scaleEffect(pressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 99, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.12)) { pressed = isPressing }
        }, perform: {})
    }
}

// MARK: – Role badge
private struct RoleBadge: View {
    let role: String

    private var color: Color {
        switch role {
        case "Superviseur": return AppColor.warning
        case "Admin": return AppColor.danger
        default: return AppColor.accent.opacity(0.8)
        }
    }

    var body: some View {
        Text(role)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: – Shimmer placeholder
private struct ShimmerRow: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 70, height: 10)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
    }
}
