import SwiftUI

struct MovementsView: View {
    @Bindable var viewModel: MovementsViewModel
    @Environment(AppContainer.self) private var container

    private let typeFilters: [MovementType?] = [nil, .entry, .exit, .adjustment, .transfer]
    @State private var showCreate = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppColor.pageGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                topSummary

                filterRail

                if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.filtered.isEmpty {
                    emptyView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            HStack {
                                Text("\(selectedCountLabel) mouvement(s)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selectedCountColor)
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)

                            ForEach(viewModel.filtered) { row in
                                MovementCardRow(row: row)
                                    .padding(.horizontal, AppSpacing.md)
                                    .onAppear {
                                        viewModel.loadMoreIfNeeded(currentRowID: row.id)
                                    }
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(AppColor.brand)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                            } else if viewModel.hasMorePages {
                                Button {
                                    Task { await viewModel.loadNextPage() }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.circle")
                                        Text("Charger plus")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColor.brand)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColor.card)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }

            // ── FAB ─────────────────────────────────────────────────────
            if !container.isReadOnly {
            Button {
                container.createMovementViewModel.reset(defaultSite: container.selectedSite)
                showCreate = true
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColor.brandGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: AppColor.brand.opacity(0.5), radius: 12, x: 0, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, AppSpacing.md)
            .padding(.bottom, 106)
            } // if !container.isReadOnly
        }
        .navigationTitle("Mouvements")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.loadOnAppear(siteId: container.selectedSite?.id)
            handlePendingQuickActionIfNeeded()
        }
        .refreshable { await viewModel.reload() }
        .onReceive(NotificationCenter.default.publisher(for: .stockMovementCreated)) { _ in
            Task { await viewModel.reload() }
        }
        .sheet(isPresented: $showCreate, onDismiss: {
            if container.createMovementViewModel.didSucceed {
                Task { await viewModel.reload() }
            }
        }, content: {
            CreateMovementView(viewModel: container.createMovementViewModel)
                .environment(container)
        })
    }

    private func handlePendingQuickActionIfNeeded() {
        guard let pendingType = container.pendingQuickMovementType else { return }
        container.pendingQuickMovementType = nil
        container.createMovementViewModel.reset(
            defaultSite: container.selectedSite,
            preferredType: pendingType
        )
        showCreate = true
    }

    private var selectedCountLabel: String {
        "\(viewModel.selectedTotalCount)"
    }

    private var selectedCountColor: Color {
        chipColor(for: viewModel.selectedType)
    }

    private var topSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColor.brandGradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: AppColor.brand.opacity(0.45), radius: 10, x: 0, y: 4)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(container.selectedSite?.name ?? "Tous les sites")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text("Suivi des entrées, sorties, ajustements et transferts")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(selectedCountLabel)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(selectedCountColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedCountColor.opacity(0.14))
                .clipShape(Capsule())
        }
        .padding(AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    private var filterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(typeFilters, id: \.self) { type in
                    FilterChip(
                        label: type?.label ?? "Tous",
                        count: countText(for: type),
                        color: chipColor(for: type),
                        isSelected: viewModel.selectedType == type
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            viewModel.selectedType = type
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, AppSpacing.md)
    }

    private func chipColor(for type: MovementType?) -> Color {
        switch type {
        case .entry:      return AppColor.success
        case .exit:       return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer:   return AppColor.accent
        case .unknown:    return AppColor.textSecondary
        case nil:         return AppColor.brand
        }
    }

    private func countText(for type: MovementType?) -> String? {
        switch type {
        case .entry:
            return "\(viewModel.countByType[.entry] ?? viewModel.rows.filter { $0.type == .entry }.count)"
        case .exit:
            return "\(viewModel.countByType[.exit] ?? viewModel.rows.filter { $0.type == .exit }.count)"
        case .adjustment:
            return "\(viewModel.countByType[.adjustment] ?? viewModel.rows.filter { $0.type == .adjustment }.count)"
        case .transfer:
            return "\(viewModel.countByType[.transfer] ?? viewModel.rows.filter { $0.type == .transfer }.count)"
        case .unknown:
            return nil
        case nil:
            return "\(viewModel.totalCount ?? viewModel.rows.count)"
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColor.danger)
            Text(message)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var loadingView: some View {
        VStack { ProgressView().tint(AppColor.brand) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.textTertiary)
            Text("Aucun mouvement trouvé")
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: – Filter chip
private struct FilterChip: View {
    let label: String
    let count: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? color : AppColor.textTertiary.opacity(0.55))
                    .frame(width: 7, height: 7)
                Text(label)
                    .font(.caption.weight(.semibold))
                if let count {
                    Text(count)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isSelected ? color.opacity(0.18) : AppColor.textTertiary.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? color.opacity(0.22)
                : AppColor.surface
            )
            .foregroundStyle(isSelected ? color : AppColor.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

// MARK: – Movement card row
private struct MovementCardRow: View {
    let row: MovementRow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(typeColor.opacity(0.16))
                        .frame(width: 40, height: 40)
                    Image(systemName: typeIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.articleName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: "barcode")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppColor.brand.opacity(0.8))
                        Text(row.articleReference)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColor.brand.opacity(0.9))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppColor.brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(quantityText)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(quantityColor)

                    // Technician avatar
                    ZStack {
                        Circle()
                            .fill(AppColor.brand.opacity(0.22))
                            .frame(width: 26, height: 26)
                        Text(row.technicianInitials)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppColor.brand)
                    }
                }
            }

            // Date row
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.textTertiary)
                Text(row.createdAt.formatted(.dateTime.day().month(.abbreviated).year().hour().minute().locale(Locale(identifier: "fr_FR"))))
                    .font(.caption2)
                    .foregroundStyle(AppColor.textTertiary)
                Spacer()
            }

            HStack(spacing: 6) {
                Text(row.type.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.18))
                    .foregroundStyle(typeColor)
                    .clipShape(Capsule())

                if !movementPath.isEmpty {
                    Text(movementPath)
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            if let reason = reasonLabel {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(AppColor.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(typeColor.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
    }

    private var movementPath: String {
        let from = row.fromSiteName
        let to = row.toSiteName

        switch row.type {
        case .entry:
            if let to, to != "-", !to.isEmpty { return "Vers \(to)" }
            return ""
        case .exit:
            return "Depuis \(from)"
        case .adjustment:
            return "Ajustement sur \(from)"
        case .transfer:
            let dest = to ?? "-"
            return "\(from) → \(dest)"
        case .unknown:
            return from
        }
    }

    private var reasonLabel: String? {
        guard let reason = row.reason?.trimmingCharacters(in: .whitespacesAndNewlines), !reason.isEmpty else {
            return nil
        }
        return "Motif: \(reason)"
    }

    private var typeColor: Color {
        switch row.type {
        case .entry:      return AppColor.success
        case .exit:       return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer:   return AppColor.accent
        case .unknown:    return AppColor.textSecondary
        }
    }

    private var typeIcon: String {
        switch row.type {
        case .entry:      return "arrow.down.circle.fill"
        case .exit:       return "arrow.up.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .transfer:   return "arrow.left.arrow.right.circle.fill"
        case .unknown:    return "questionmark.circle.fill"
        }
    }

    private var quantityText: String {
        row.quantity >= 0 ? "+\(row.quantity)" : "\(row.quantity)"
    }

    private var quantityColor: Color {
        switch row.type {
        case .entry:      return AppColor.success
        case .exit:       return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer:   return AppColor.accent
        case .unknown:    return AppColor.textSecondary
        }
    }
}

