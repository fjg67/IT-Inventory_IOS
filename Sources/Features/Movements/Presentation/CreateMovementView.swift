import SwiftUI

struct CreateMovementView: View {
    @Bindable var viewModel: CreateMovementViewModel
    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.pageGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Type picker ─────────────────────────────────
                        typePickerSection

                        // ── Article ─────────────────────────────────────
                        articleSection

                        // ── Sites ────────────────────────────────────────
                        siteSection

                        // ── Quantité ─────────────────────────────────────
                        quantitySection

                        // ── Motif ────────────────────────────────────────
                        reasonSection

                        // ── Erreur ───────────────────────────────────────
                        if let err = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(err)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // ── Bouton enregistrer ───────────────────────────
                        submitButton
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.lg)
                }

                // ── Success overlay ──────────────────────────────────
                if showSuccess {
                    MovementSuccessOverlay(type: viewModel.selectedType)
                        .transition(.opacity)
                        .zIndex(99)
                }
            }
            .navigationTitle("Nouveau mouvement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .task { await viewModel.loadContext(defaultSite: container.selectedSite) }
        .onChange(of: viewModel.didSucceed) { _, success in
            guard success else { return }
            withAnimation(.easeIn(duration: 0.2)) { showSuccess = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                await MainActor.run { dismiss() }
            }
        }
    }

    // MARK: - Type picker

    private var typePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Type de mouvement")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach([MovementType.entry, .exit, .adjustment, .transfer], id: \.self) { type in
                    TypeCard(type: type, isSelected: viewModel.selectedType == type) {
                        viewModel.selectedType = type
                    }
                }
            }
        }
    }

    // MARK: - Article picker

    private var articleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Article")

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColor.textTertiary)
                    TextField("Rechercher un article…", text: $viewModel.articleSearch)
                        .autocorrectionDisabled()
                        .foregroundStyle(AppColor.textPrimary)
                        .onChange(of: viewModel.articleSearch) { _, q in
                            if viewModel.selectedArticle?.name != q {
                                viewModel.selectedArticle = nil
                            }
                            viewModel.onArticleSearchChanged(q)
                        }
                    if viewModel.isSearching {
                        ProgressView().tint(AppColor.brand).scaleEffect(0.8)
                    } else if viewModel.selectedArticle != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColor.success)
                    }
                }
                .padding(12)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !viewModel.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { article in
                            Button {
                                viewModel.selectArticle(article)
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(article.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(AppColor.textPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: 4) {
                                            Image(systemName: "barcode")
                                                .font(.system(size: 9))
                                                .foregroundStyle(AppColor.brand.opacity(0.8))
                                            Text(article.reference)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(AppColor.brand.opacity(0.9))
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(AppColor.brand)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            if article.id != viewModel.searchResults.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.07))
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .background(AppColor.card.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColor.brand.opacity(0.25), lineWidth: 1)
                    )
                }
            }

            if let article = viewModel.selectedArticle {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppColor.success)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(article.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                        Text(article.reference)
                            .font(.caption.monospaced())
                            .foregroundStyle(AppColor.brand.opacity(0.8))
                    }
                    Spacer()
                    Button {
                        viewModel.selectedArticle = nil
                        viewModel.articleSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColor.textTertiary)
                    }
                }
                .padding(10)
                .background(AppColor.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColor.success.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Sites

    @ViewBuilder
    private var siteSection: some View {
        switch viewModel.selectedType {
        case .entry:
            SitePickerField(
                label: "Site de destination",
                icon: "building.2.fill",
                iconColor: AppColor.success,
                selection: $viewModel.toSite,
                sites: viewModel.availableSites
            )
        case .exit:
            SitePickerField(
                label: "Site source",
                icon: "building.2",
                iconColor: AppColor.danger,
                selection: $viewModel.fromSite,
                sites: viewModel.availableSites
            )
        case .adjustment:
            SitePickerField(
                label: "Site concerné",
                icon: "slider.horizontal.3",
                iconColor: AppColor.warning,
                selection: $viewModel.fromSite,
                sites: viewModel.availableSites
            )
        case .transfer:
            VStack(spacing: 12) {
                SitePickerField(
                    label: "Site source",
                    icon: "arrow.up.circle",
                    iconColor: AppColor.brand,
                    selection: $viewModel.fromSite,
                    sites: viewModel.availableSites
                )
                SitePickerField(
                    label: "Site destination",
                    icon: "arrow.down.circle",
                    iconColor: AppColor.accent,
                    selection: $viewModel.toSite,
                    sites: viewModel.availableSites
                )
            }
        case .unknown:
            EmptyView()
        }
    }

    // MARK: - Quantity

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(viewModel.selectedType == .adjustment ? "Quantité (delta)" : "Quantité")
            HStack(spacing: 16) {
                Button {
                    if viewModel.quantity > 1 { viewModel.quantity -= 1 }
                } label: {
                    ZStack {
                        Circle().fill(AppColor.card).frame(width: 40, height: 40)
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(viewModel.quantity > 1 ? .white : AppColor.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                Text("\(viewModel.quantity)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(minWidth: 48)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.quantity += 1
                } label: {
                    ZStack {
                        Circle().fill(AppColor.brand).frame(width: 40, height: 40)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Quick picks
                ForEach([5, 10, 25], id: \.self) { val in
                    Button {
                        viewModel.quantity = val
                    } label: {
                        Text("\(val)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(viewModel.quantity == val ? AppColor.brand : AppColor.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(viewModel.quantity == val ? AppColor.brand.opacity(0.15) : AppColor.card)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Reason

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Motif (optionnel)")
            TextField("Ex : retour fournisseur, inventaire…", text: $viewModel.reason, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .autocorrectionDisabled()
                .foregroundStyle(AppColor.textPrimary)
                .padding(12)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            let userId = container.selectedTechnician?.id ?? ""
            let technicianName = container.selectedTechnician?.name ?? "Technicien inconnu"
            Task { await viewModel.submit(userId: userId, technicianName: technicianName) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(viewModel.canSubmit ? AppColor.brandGradient : LinearGradient(colors: [AppColor.textTertiary.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 52)
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Enregistrer le mouvement")
                            .font(.headline)
                    }
                    .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSubmit)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColor.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - TypeCard

private struct TypeCard: View {
    let type: MovementType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.3 : 0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(type.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : AppColor.textSecondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                        .font(.caption)
                }
            }
            .padding(12)
            .background(isSelected ? color.opacity(0.12) : AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.07), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var color: Color {
        switch type {
        case .entry:      return AppColor.success
        case .exit:       return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer:   return AppColor.brand
        case .unknown:    return AppColor.textSecondary
        }
    }

    private var icon: String {
        switch type {
        case .entry:      return "arrow.down.circle.fill"
        case .exit:       return "arrow.up.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .transfer:   return "arrow.left.arrow.right.circle.fill"
        case .unknown:    return "questionmark.circle"
        }
    }
}

// MARK: - SitePickerField

private struct SitePickerField: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var selection: Site?
    let sites: [Site]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Menu {
                ForEach(sites, id: \.id) { site in
                    Button(site.name) { selection = site }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .frame(width: 20)
                    Text(selection?.name ?? "Sélectionner un site")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection != nil ? AppColor.textPrimary : AppColor.textTertiary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColor.textTertiary)
                }
                .padding(12)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selection != nil ? iconColor.opacity(0.3) : Color.white.opacity(0.07), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - MovementSuccessOverlay

private struct MovementSuccessOverlay: View {
    let type: MovementType

    @State private var circleScale: CGFloat = 0.4
    @State private var circleOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: Double = 0
    @State private var labelOffset: CGFloat = 18
    @State private var labelOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0.6
    @State private var rippleOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(bgOpacity)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    // Ripple ring
                    Circle()
                        .stroke(typeColor.opacity(rippleOpacity), lineWidth: 3)
                        .frame(width: 130, height: 130)
                        .scaleEffect(rippleScale)

                    // Main circle
                    Circle()
                        .fill(typeColor.opacity(0.18))
                        .frame(width: 100, height: 100)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)

                    // Icon
                    Image(systemName: typeIcon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(typeColor)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                }

                VStack(spacing: 6) {
                    Text(typeTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(typeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .offset(y: labelOffset)
                .opacity(labelOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.25)) {
            bgOpacity = 1
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
            circleScale = 1
            circleOpacity = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.15)) {
            iconScale = 1
            iconOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2)) {
            labelOffset = 0
            labelOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
            rippleScale = 1.4
            rippleOpacity = 0
        }
    }

    private var typeColor: Color {
        switch type {
        case .entry:      return AppColor.success
        case .exit:       return AppColor.danger
        case .adjustment: return AppColor.warning
        case .transfer:   return AppColor.brand
        case .unknown:    return AppColor.textSecondary
        }
    }

    private var typeIcon: String {
        switch type {
        case .entry:      return "arrow.down.circle.fill"
        case .exit:       return "arrow.up.circle.fill"
        case .adjustment: return "checkmark.circle.fill"
        case .transfer:   return "arrow.left.arrow.right.circle.fill"
        case .unknown:    return "checkmark.circle.fill"
        }
    }

    private var typeTitle: String {
        switch type {
        case .entry:      return "Entrée enregistrée"
        case .exit:       return "Sortie enregistrée"
        case .adjustment: return "Ajustement effectué"
        case .transfer:   return "Transfert effectué"
        case .unknown:    return "Mouvement enregistré"
        }
    }

    private var typeSubtitle: String {
        switch type {
        case .entry:      return "Le stock a été mis à jour"
        case .exit:       return "L'article a été sorti du stock"
        case .adjustment: return "La quantité a été ajustée"
        case .transfer:   return "L'article a été transféré"
        case .unknown:    return "Opération réussie"
        }
    }
}
