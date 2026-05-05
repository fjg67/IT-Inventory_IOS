import SwiftUI

struct RootTabView: View {
    @Environment(AppContainer.self) private var container
    @State private var showSitePicker = false

    private var filteredSites: [Site] {
        guard let current = container.selectedSite else { return [] }
        if let parentId = current.parentSiteId {
            // Site is a child → show all siblings (same parent)
            return container.availableSites.filter { $0.parentSiteId == parentId }
        }
        // Site is a parent → show self + all children
        let children = container.availableSites.filter { $0.parentSiteId == current.id }
        if children.isEmpty {
            // No children loaded yet, show all sites that have this site as parent or are this site
            return container.availableSites.filter { $0.id == current.id || $0.parentSiteId == current.id }
        }
        return [current] + children
    }

    var body: some View {
        currentTabContent
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomTabBar
            }
            .confirmationDialog(
                "Changer de site",
                isPresented: $showSitePicker,
                titleVisibility: .visible
            ) {
                ForEach(filteredSites) { site in
                    Button(site.name) {
                        container.selectedSite = site
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Sélectionnez votre site de travail")
            }
            .task {
                await container.loadAvailableSitesIfNeeded()
            }
    }

    @ViewBuilder
    private var currentTabContent: some View {
        switch container.selectedTab {
        case .dashboard:
            NavigationStack {
                HomeView(
                    viewModel: container.makeHomeViewModel(),
                    selectedSiteId: container.selectedSite?.id,
                    onScannerTap: {
                        container.selectedTab = .scan
                    },
                    onActionTap: { action in
                        switch action {
                        case .entry:
                            container.pendingQuickMovementType = .entry
                            container.selectedTab = .movements
                        case .exit:
                            container.pendingQuickMovementType = .exit
                            container.selectedTab = .movements
                        case .transfer:
                            container.pendingQuickMovementType = .transfer
                            container.selectedTab = .movements
                        case .articles:
                            container.selectedTab = .articles
                        }
                    },
                    onSeeAllMovements: {
                        container.selectedTab = .movements
                    },
                    onSiteTap: {
                        showSitePicker = true
                    }
                )
            }

        case .articles:
            NavigationStack {
                ArticlesView(
                    viewModel: container.articlesViewModel,
                    selectedSiteId: container.selectedSite?.id,
                    makeAddArticleViewModel: container.makeAddArticleViewModel,
                    onOpenCreatePC: {
                        container.selectedTab = .pc
                    },
                    onOpenScan: {
                        container.selectedTab = .scan
                    },
                    makeDetailViewModel: container.makeArticleStockViewModel
                )
            }

        case .scan:
            NavigationStack {
                ScanView(
                    viewModel: container.makeScanViewModel(),
                    makeDetailViewModel: container.makeArticleStockViewModel
                )
            }

        case .pc:
            NavigationStack {
                PCView(viewModel: container.pcViewModel)
            }

        case .movements:
            NavigationStack {
                MovementsView(viewModel: container.movementsViewModel)
            }

        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }

    private var bottomTabBar: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        container.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(container.selectedTab == tab ? AppColor.brand : AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if container.selectedTab == tab {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppColor.brand.opacity(0.18))
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.xs)
        .padding(.bottom, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.card.opacity(0.88))
                .overlay(.ultraThinMaterial.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
    }
}
