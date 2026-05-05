import Charts
import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel
    @Environment(AppContainer.self) private var container

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    header
                    kpiGrid
                    quickActionsSection
                    recentMovementsSection
                    trendCard
                    scanCTA
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear { viewModel.loadOnAppear(siteId: container.selectedSite?.id) }
        .refreshable { await viewModel.reload(siteId: container.selectedSite?.id) }
        .onReceive(NotificationCenter.default.publisher(for: .stockMovementCreated)) { _ in
            Task { await viewModel.reload(siteId: container.selectedSite?.id) }
        }
    }

    // MARK: – Header
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                Text("Stock Ops")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                if let site = container.selectedSite {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColor.accent)
                        Text(site.name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColor.accent)
                    }
                }
            }
            Spacer()
            if let tech = container.selectedTechnician {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.brand, AppColor.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                            .shadow(color: AppColor.brand.opacity(0.5), radius: 10, x: 0, y: 4)
                        Text(tech.initials)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                    }

                }
            } else {
                ZStack {
                    Circle()
                        .fill(AppColor.brandGradient)
                        .frame(width: 46, height: 46)
                        .shadow(color: AppColor.brand.opacity(0.5), radius: 10, x: 0, y: 4)
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .padding(.top, AppSpacing.md)
    }

    // MARK: – KPI Grid
    private var kpiGrid: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                kpiCard(
                    title: "Articles en stock",
                    value: viewModel.isLoading ? "—" : "\(viewModel.activeArticleCount)",
                    icon: "tag.fill",
                    iconBg: LinearGradient(colors: [AppColor.brand, AppColor.brandDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                    glowColor: AppColor.brand
                )
                kpiCard(
                    title: "Alertes stock",
                    value: viewModel.isLoading ? "—" : "\(viewModel.lowStockAlertCount)",
                    icon: "exclamationmark.triangle.fill",
                    iconBg: LinearGradient(colors: [AppColor.warning, Color(red: 0.9, green: 0.5, blue: 0.0)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                    glowColor: AppColor.warning
                )
            }
            HStack(spacing: AppSpacing.sm) {
                kpiCard(
                    title: "Stock total",
                    value: viewModel.isLoading ? "—" : "\(viewModel.totalStock)",
                    icon: "shippingbox.fill",
                    iconBg: LinearGradient(colors: [AppColor.accent, AppColor.accentDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                    glowColor: AppColor.accent
                )
                kpiCard(
                    title: "Mouvements",
                    value: viewModel.isLoading ? "—" : "\(viewModel.todayMovementCount)",
                    icon: "arrow.left.arrow.right",
                    iconBg: LinearGradient(colors: [AppColor.success, Color(red: 0.1, green: 0.65, blue: 0.35)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                    glowColor: AppColor.success
                )
            }
        }
    }

    private func kpiCard(
        title: String,
        value: String,
        icon: String,
        iconBg: LinearGradient,
        glowColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 42, height: 42)
                    .shadow(color: glowColor.opacity(0.45), radius: 8, x: 0, y: 4)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    // MARK: – Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Actions rapides")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppColor.textPrimary)

            HStack(spacing: AppSpacing.sm) {
                quickActionButton(label: "Entrée", icon: "arrow.down.circle.fill",
                                  color: .green, tab: .movements)
                quickActionButton(label: "Sortie", icon: "arrow.up.circle.fill",
                                  color: Color(red: 1, green: 0.35, blue: 0.35), tab: .movements)
                quickActionButton(label: "Articles", icon: "shippingbox.fill",
                                  color: AppColor.brand, tab: .articles)
                quickActionButton(label: "Transfert", icon: "arrow.left.arrow.right.circle.fill",
                                  color: Color(red: 0.3, green: 0.6, blue: 1), tab: .movements)
            }
        }
    }

    private func quickActionButton(label: String, icon: String, color: Color, tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                container.selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(color.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Recent Movements
    private var recentMovementsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Derniers mouvements")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Button { container.selectedTab = .movements } label: {
                    Text("Voir tout")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(AppColor.accent)
                    Spacer()
                }
                .padding(.vertical, 20)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if viewModel.recentMovements.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(AppColor.textTertiary)
                        Text("Aucun mouvement récent")
                            .font(.caption)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentMovements.enumerated()), id: \.element.id) { index, item in
                        recentMovementRow(item)
                        if index < viewModel.recentMovements.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.07))
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
            }
        }
    }

    private func recentMovementRow(_ item: RecentMovementItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.typeColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: item.typeIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.typeColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.articleName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(item.typeLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(item.typeColor)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(AppColor.textTertiary)
                    Text(item.articleReference)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.quantity > 0 ? "+\(item.quantity)" : "\(item.quantity)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.quantity > 0 ? Color.green : Color(red: 1, green: 0.35, blue: 0.35))
                Text(item.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
    }

    // MARK: – Trend
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendance")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Mouvements des 7 derniers jours")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(AppColor.accent)
                    .font(.title3)
            }

            Chart(viewModel.trend) { point in
                LineMark(
                    x: .value("Jour", point.day),
                    y: .value("Mouvements", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(colors: [AppColor.accent, AppColor.brand],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Jour", point.day),
                    y: .value("Mouvements", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColor.brand.opacity(0.30), AppColor.accent.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Jour", point.day),
                    y: .value("Mouvements", point.value)
                )
                .symbolSize(30)
                .foregroundStyle(AppColor.accent)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel()
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(AppColor.danger)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    // MARK: – Scan CTA
    private var scanCTA: some View {
        XXLScanButton { /* handled by tab navigation */ }
    }
}
