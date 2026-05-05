// HomeView.swift
import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @StateObject private var viewModel: HomeViewModel
    private let onScannerTap: () -> Void
    private let onActionTap: (HomeQuickActionKind) -> Void
    private let onSeeAllMovements: () -> Void
    private let onSiteTap: () -> Void
    private let selectedSiteId: String?

    @State private var showKPI = false
    @State private var showRows = false

    init(
        viewModel: HomeViewModel,
        selectedSiteId: String?,
        onScannerTap: @escaping () -> Void,
        onActionTap: @escaping (HomeQuickActionKind) -> Void,
        onSeeAllMovements: @escaping () -> Void,
        onSiteTap: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.selectedSiteId = selectedSiteId
        self.onScannerTap = onScannerTap
        self.onActionTap = onActionTap
        self.onSeeAllMovements = onSeeAllMovements
        self.onSiteTap = onSiteTap
    }

    var body: some View {
        ZStack {
            OpsCrystal.pageGradient.ignoresSafeArea()
            ambientOrbs

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerSection
                    kpiBanner
                    ScannerButton { onScannerTap() }
                    if !container.isReadOnly {
                        actionsGrid
                    }
                    movementsSection
                    TrendChartView(points: viewModel.trendPoints)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 110)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
                showKPI = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showRows = true
            }
        }
        .task(id: selectedSiteId) {
            await viewModel.load(siteId: selectedSiteId)
        }
    }

    // MARK: - Ambient background glows
    private var ambientOrbs: some View {
        ZStack {
            Ellipse()
                .fill(OpsCrystal.accentPrimary.opacity(0.18))
                .frame(width: 320, height: 220)
                .blur(radius: 100)
                .offset(x: -90, y: -280)
            Ellipse()
                .fill(OpsCrystal.accentSecondary.opacity(0.10))
                .frame(width: 260, height: 180)
                .blur(radius: 80)
                .offset(x: 150, y: 60)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Header
    private var technicianFirstName: String {
        container.selectedTechnician.flatMap { $0.name.split(separator: " ").first.map(String.init) } ?? "Dashboard"
    }
    private var technicianInitials: String {
        container.selectedTechnician?.initials ?? viewModel.initials
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [OpsCrystal.accentPrimary, OpsCrystal.accentSecondary],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                    .shadow(color: OpsCrystal.accentPrimary.opacity(0.45), radius: 14, x: 0, y: 5)
                Text(technicianInitials)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
            }

            // Greeting + name
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(OpsCrystal.textSecondary)
                Text(technicianFirstName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(OpsCrystal.textPrimary)
            }

            Spacer()

            // Site pill — changement de site accessible à tous
            Button(action: onSiteTap) {
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(container.selectedSite?.name ?? "—")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(OpsCrystal.accentSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(OpsCrystal.accentSecondary.opacity(0.12))
                        .overlay(
                            Capsule().stroke(OpsCrystal.accentSecondary.opacity(0.28), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Unified KPI Banner
    private var kpiBanner: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.kpis.enumerated()), id: \.element.id) { index, item in
                KPICardView(item: item, appear: showKPI, delay: Double(index) * 0.12)
                if index < viewModel.kpis.count - 1 {
                    Rectangle()
                        .fill(OpsCrystal.border)
                        .frame(width: 1)
                        .padding(.vertical, 22)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(OpsCrystal.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(OpsCrystal.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Actions 2x2 grid
    private var actionsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Actions rapides")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.actions) { action in
                    QuickActionButton(action: action) { onActionTap(action.kind) }
                }
            }
        }
    }

    // MARK: - Recent movements
    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Activite recente")
                Spacer()
                Button(action: onSeeAllMovements) {
                    HStack(spacing: 3) {
                        Text("Voir tout")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OpsCrystal.accentSecondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                if viewModel.recentMovements.isEmpty {
                    Text("Aucun mouvement recent")
                        .font(.system(size: 14))
                        .foregroundStyle(OpsCrystal.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    ForEach(Array(viewModel.recentMovements.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            MovementRowView(item: item, appear: showRows, delay: Double(index) * 0.05)
                            if index < viewModel.recentMovements.count - 1 {
                                Rectangle()
                                    .fill(OpsCrystal.border)
                                    .frame(height: 1)
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(OpsCrystal.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(OpsCrystal.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Helpers
    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.1)
            .foregroundStyle(OpsCrystal.textSecondary)
    }
}
