import SwiftUI

struct SiteSelectionView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SiteSelectionViewModel
    @State private var orbs = false

    init(viewModel: SiteSelectionViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────
            AppColor.page.ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(AppColor.brand.opacity(0.22))
                    .blur(radius: 80)
                    .frame(width: 320, height: 320)
                    .offset(x: geo.size.width - 120, y: -60 + (orbs ? 15 : -15))
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: orbs)

                Circle()
                    .fill(AppColor.accent.opacity(0.12))
                    .blur(radius: 70)
                    .frame(width: 260, height: 260)
                    .offset(x: -80, y: geo.size.height * 0.55 + (orbs ? -10 : 10))
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: orbs)
            }
            .ignoresSafeArea()

            // ── Content ─────────────────────────────────────────────
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if let parent = viewModel.selectedParent {
                // Step 2 – sub-sites
                stepView(
                    icon: "mappin.and.ellipse",
                    title: parent.name,
                    subtitle: "Choisissez un sous-site",
                    sites: viewModel.children(of: parent),
                    onBack: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            viewModel.selectedParent = nil
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                // Step 1 – top-level sites
                stepView(
                    icon: "building.2.fill",
                    title: "Choisir un site",
                    subtitle: "Sélectionnez votre site de travail",
                    sites: viewModel.topLevelSites,
                    onBack: nil
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            orbs = true
            viewModel.loadSites()
        }
    }

    // MARK: – Step screen
    private func stepView(
        icon: String,
        title: String,
        subtitle: String,
        sites: [Site],
        onBack: (() -> Void)?
    ) -> some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                if let onBack {
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
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)

            Spacer()

            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColor.brandGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: AppColor.brand.opacity(0.4), radius: 16, x: 0, y: 6)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer().frame(height: 40)

            // Sites list
            VStack(spacing: 0) {
                ForEach(Array(sites.enumerated()), id: \.element.id) { index, site in
                    let isLocked = site.name == "Agences"
                    SiteCard(
                        site: site,
                        hasChildren: viewModel.hasChildren(site),
                        isFirst: index == 0,
                        isLast: index == sites.count - 1,
                        isLocked: isLocked
                    ) {
                        guard !isLocked else { return }
                        if viewModel.hasChildren(site) {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                viewModel.selectedParent = site
                            }
                        } else {
                            container.selectedSite = site
                            dismiss()
                        }
                    }
                    if index < sites.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                            .background(Color.clear)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, AppSpacing.md)

            Spacer()

            // Sign out
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

    // MARK: – Loading
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppColor.card)
                    .frame(height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            }
            .padding(.horizontal, AppSpacing.md)
            Spacer()
        }
    }

    // MARK: – Error
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColor.warning)
            Text(error)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Button("Réessayer") {
                Task { await viewModel.reload() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColor.brand)
            Spacer()
        }
    }
}

// MARK: – Site card
private struct SiteCard: View {
    let site: Site
    let hasChildren: Bool
    let isFirst: Bool
    let isLast: Bool
    let isLocked: Bool
    let onSelect: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isLocked
                            ? AnyShapeStyle(Color.gray.opacity(0.25))
                            : AnyShapeStyle(AppColor.brandGradient))
                        .frame(width: 38, height: 38)
                    Image(systemName: isLocked ? "lock.fill" : (hasChildren ? "building.2.fill" : "mappin.circle.fill"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isLocked ? Color.gray : .white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(site.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isLocked ? AppColor.textTertiary : AppColor.textPrimary)
                    if isLocked {
                        Text("Bientôt disponible")
                            .font(.caption2)
                            .foregroundStyle(AppColor.textTertiary.opacity(0.7))
                    }
                }

                Spacer()

                if !isLocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(AppColor.card)
            .opacity(isLocked ? 0.6 : 1.0)
            .scaleEffect(pressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .onLongPressGesture(minimumDuration: 99, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) { pressed = isPressing }
        }, perform: {})
    }
}
