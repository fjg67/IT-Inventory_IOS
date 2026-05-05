import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @State private var viewModel: ArticleStockViewModel
    @State private var selectedMovementType: MovementType? = nil
    @State private var pendingActionType: MovementType? = nil
    @Environment(AppContainer.self) private var container

    init(article: Article, viewModel: ArticleStockViewModel) {
        self.article = article
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    heroSection

                    VStack(spacing: AppSpacing.md) {
                        quickMetricsCard
                        if !container.isReadOnly {
                            actionButtonsCard
                        }
                        identificationCard

                        if let description = clean(article.descriptionText) {
                            descriptionCard(description)
                        }

                        movementsCard

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AppColor.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .navigationTitle(article.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.loadOnAppear() }
        .refreshable { await viewModel.reload() }
        .sheet(item: $pendingActionType) { type in
            ArticleMovementSheet(
                article: article,
                type: type,
                availableSites: [],
                currentSiteId: viewModel.selectedSiteId
            ) { quantity, reason, targetSiteId in
                guard let techId = container.selectedTechnician?.id else { return }
                let techName = container.selectedTechnician?.name ?? "Technicien inconnu"
                Task {
                    try? await viewModel.createMovement(
                        type: type,
                        quantity: quantity,
                        reason: reason,
                        technicianId: techId,
                        technicianName: techName,
                        targetSiteId: targetSiteId
                    )
                    pendingActionType = nil
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    private var totalStock: Int {
        viewModel.stockRows.reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Action Buttons Card
    private var actionButtonsCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Mouvement de stock", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // Divider
            Rectangle()
                .fill(AppColor.separator.opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // Buttons grid
            HStack(spacing: 0) {
                actionCell(label: "Entrée", icon: "arrow.down.circle.fill", color: AppColor.success, type: .entry)
                dividerV
                actionCell(label: "Sortie", icon: "arrow.up.circle.fill", color: AppColor.danger, type: .exit)
                dividerV
                actionCell(label: "Ajust.", icon: "slider.horizontal.3", color: AppColor.warning, type: .adjustment)
                dividerV
                actionCell(label: "Transfert", icon: "arrow.triangle.swap", color: AppColor.accent, type: .transfer)
            }
            .padding(.vertical, 6)
        }
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var dividerV: some View {
        Rectangle()
            .fill(AppColor.separator.opacity(0.5))
            .frame(width: 0.5)
            .padding(.vertical, 14)
    }

    private func actionCell(label: String, icon: String, color: Color, type: MovementType) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            pendingActionType = type
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.14))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero
    private var heroSection: some View {
            ZStack(alignment: .bottomLeading) {
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            heroPlaceholder
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 270)
                                .clipped()
                        case .failure:
                            heroPlaceholder
                        @unknown default:
                            heroPlaceholder
                        }
                    }
                } else {
                    heroPlaceholder
                }

                LinearGradient(
                    colors: [.clear, AppColor.page.opacity(0.85), AppColor.page],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .frame(maxWidth: .infinity, alignment: .bottom)

                VStack(alignment: .leading, spacing: 10) {
                    Text(article.name)
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        badge("Ref \(article.reference)", tint: AppColor.accent)

                        if let category = clean(article.category) {
                            badge(category, tint: AppColor.brand)
                        }

                        badge(article.isArchived ? "Archive" : "Actif", tint: article.isArchived ? AppColor.warning : AppColor.success)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 270)
        }

        private var heroPlaceholder: some View {
            ZStack {
                LinearGradient(
                    colors: [AppColor.brandDeep.opacity(0.8), AppColor.brand.opacity(0.35), AppColor.page],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 10) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(AppColor.brand.opacity(0.65))

                    Text("Aucune image article")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }

        // MARK: - Cards
        private var quickMetricsCard: some View {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                sectionHeader(title: "⚡ Vue rapide", icon: "speedometer", color: AppColor.accent)

                HStack(spacing: AppSpacing.sm) {
                    metricTile(title: "📦 Stock total", value: "\(totalStock)", tint: totalStock > 0 ? AppColor.success : AppColor.danger)
                    metricTile(title: "⚠️ Stock min.", value: "\(article.minStock)", tint: AppColor.warning)
                    metricTile(title: "📏 Unité", value: clean(article.unit) ?? "-", tint: AppColor.brand)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
            .cardStyle()
        }

        private var identificationCard: some View {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(title: "🧾 Données article", icon: "doc.text.fill", color: AppColor.brand)

                VStack(spacing: 0) {
                    infoRow(label: "🔖 Référence", value: article.reference)
                    infoRow(label: "📝 Nom", value: article.name)
                    infoRow(label: "🗂️ Catégorie", value: clean(article.category) ?? "-")
                    infoRow(label: "🏷️ Marque", value: clean(article.brand) ?? "-")
                    infoRow(label: "🧠 Modèle", value: clean(article.model) ?? "-")
                    infoRow(label: "🧩 Type article", value: clean(article.articleType) ?? "-")
                    infoRow(label: "🔎 Sous-type", value: clean(article.sousType) ?? "-")
                    infoRow(label: "🧬 Code famille", value: clean(article.codeFamille) ?? "-")
                    infoRow(label: "📍 Emplacement", value: clean(article.emplacement) ?? "-")
                    infoRow(label: "📶 Code-barres", value: clean(article.barcode) ?? "-")
                    infoRow(label: "✅ Statut", value: article.isArchived ? "Archivé" : "Actif", isLast: true)
                }
            }
            .cardStyle()
        }

        private func descriptionCard(_ description: String) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(title: "💬 Description", icon: "text.alignleft", color: AppColor.accent)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
            }
            .cardStyle()
        }

        // MARK: - Movements
        private var filteredMovements: [MovementRow] {
            guard let type = selectedMovementType else { return viewModel.recentMovements }
            return viewModel.recentMovements.filter { $0.type == type }
        }

        private var movementsCard: some View {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(title: "🔄 Mouvements", icon: "arrow.left.arrow.right", color: AppColor.success)

                // Type filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        typePill(label: "Tous", type: nil)
                        typePill(label: "Entrée", type: .entry)
                        typePill(label: "Sortie", type: .exit)
                        typePill(label: "Ajustement", type: .adjustment)
                        typePill(label: "Transfert", type: .transfer)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                }

                if viewModel.isLoading {
                    HStack { Spacer(); ProgressView().tint(AppColor.accent); Spacer() }
                        .padding(.vertical, AppSpacing.lg)
                } else if filteredMovements.isEmpty {
                    Text(selectedMovementType == nil ? "Aucun mouvement pour ce site" : "Aucun mouvement de ce type")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppSpacing.lg)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredMovements.prefix(20).enumerated()), id: \.element.id) { index, row in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(movementColor(row.type).opacity(0.18))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: movementIcon(row.type))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(movementColor(row.type))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(row.type.label)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text(locationText(from: row.fromSiteName, to: row.toSiteName))
                                        .font(.caption)
                                        .foregroundStyle(AppColor.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(row.quantity >= 0 ? "+\(row.quantity)" : "\(row.quantity)")
                                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                                        .foregroundStyle(row.quantity >= 0 ? AppColor.success : AppColor.danger)
                                    Text(shortDate(row.createdAt))
                                        .font(.caption2)
                                        .foregroundStyle(AppColor.textTertiary)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, 11)

                            if index < min(filteredMovements.count, 20) - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, AppSpacing.md + 40 + 14)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
            .cardStyle()
        }

        private func typePill(label: String, type: MovementType?) -> some View {
            let isSelected = selectedMovementType == type
            let tint: Color = {
                switch type {
                case .entry:      return AppColor.success
                case .exit:       return AppColor.danger
                case .adjustment: return AppColor.warning
                case .transfer:   return AppColor.accent
                default:          return AppColor.brand
                }
            }()
            return Button {
                withAnimation(.easeInOut(duration: 0.18)) { selectedMovementType = type }
            } label: {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? tint : tint.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(tint.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }

        private func movementIcon(_ type: MovementType) -> String {
            switch type {
            case .entry:      return "arrow.down.circle.fill"
            case .exit:       return "arrow.up.circle.fill"
            case .adjustment: return "slider.horizontal.3"
            case .transfer:   return "arrow.left.arrow.right"
            case .unknown:    return "questionmark.circle"
            }
        }

        private func shortDate(_ date: Date) -> String {
            let cal = Calendar.current
            if cal.isDateInToday(date) {
                return date.formatted(date: .omitted, time: .shortened)
            } else if cal.isDateInYesterday(date) {
                return "Hier"
            } else {
                return date.formatted(.dateTime.day().month(.abbreviated))
            }
        }

        // MARK: - Helpers
        private func sectionHeader(title: String, icon: String, color: Color) -> some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)
        }

        private func metricTile(title: String, value: String, tint: Color) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(AppColor.surface.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }

        private func badge(_ text: String, tint: Color) -> some View {
            Text(text)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(AppColor.textPrimary)
                .background(tint.opacity(0.28))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(tint.opacity(0.7), lineWidth: 1)
                )
        }

        private func infoRow(label: String, value: String, isLast: Bool = false) -> some View {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer(minLength: 12)
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 12)
                if !isLast {
                    Divider().background(Color.white.opacity(0.06)).padding(.leading, AppSpacing.md)
                }
            }
        }

        private func clean(_ value: String?) -> String? {
            guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
                return nil
            }
            return raw
        }

        private func formatDate(_ date: Date) -> String {
            date.formatted(date: .abbreviated, time: .shortened)
        }

        private func locationText(from: String, to: String?) -> String {
            if let to, let cleanTo = clean(to) {
                return "\(from) -> \(cleanTo)"
            }
            return from
        }

        private func movementColor(_ type: MovementType) -> Color {
            switch type {
            case .entry:      return AppColor.success
            case .exit:       return AppColor.danger
            case .adjustment: return AppColor.warning
            case .transfer:   return AppColor.accent
            case .unknown:    return AppColor.textTertiary
            }
        }
    }

    private extension View {
        func cardStyle() -> some View {
            self
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        }
    }

