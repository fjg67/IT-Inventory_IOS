import SwiftUI

struct PCView: View {
    @Bindable var viewModel: PCViewModel
    @Environment(AppContainer.self) private var container

    @State private var showCreatePage = false
    @State private var selectedForSend: Article?
    @State private var destinationAgency = ""
    @State private var recipientName = ""
    @State private var technicianName = ""
    @State private var exportURL: URL?

    var body: some View {
        ZStack {
            AppColor.pageGradient.ignoresSafeArea()
            ambientOrbs

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerSection
                    headerCounters

                    if viewModel.selectedHeaderFilter != .sent {
                        filtersSection
                    }

                    contentSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, 170)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            if viewModel.selectedHeaderFilter == .sent,
               let exportURL {
                ShareLink(item: exportURL) {
                    Label("Exporter CSV", systemImage: "square.and.arrow.up")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.selectedHeaderFilter != .sent {
                addPCButton
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 106)
            }
        }
        .sheet(item: $selectedForSend) { article in
            sendSheet(article: article)
        }
        .navigationDestination(isPresented: $showCreatePage) {
            AddPCView(viewModel: viewModel)
        }
        .onChange(of: viewModel.selectedHeaderFilter) { _, newValue in
            if newValue == .sent {
                exportURL = makeCSVFile(records: viewModel.sentHistory)
            }
        }
        .task(id: container.selectedSite?.id) {
            await viewModel.reload(siteId: container.selectedSite?.id)
        }
        .refreshable { await viewModel.reload(siteId: container.selectedSite?.id) }
    }

    private var addPCButton: some View {
        Button {
            showCreatePage = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(AppColor.brandGradient)
                    .clipShape(Circle())

                Text("Nouveau PC")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 4)
            .shadow(color: AppColor.brand.opacity(0.32), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var ambientOrbs: some View {
        ZStack {
            Circle()
                .fill(AppColor.brand.opacity(0.18))
                .blur(radius: 80)
                .frame(width: 260, height: 260)
                .offset(x: -140, y: -320)

            Circle()
                .fill(AppColor.accent.opacity(0.12))
                .blur(radius: 100)
                .frame(width: 280, height: 280)
                .offset(x: 160, y: -220)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Parc PC")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)

            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                Text(container.selectedSite?.name ?? "Tous les sites")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(AppColor.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColor.accent.opacity(0.12))
            .clipShape(Capsule())

            Text(subtitleText)
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleText: String {
        switch viewModel.selectedHeaderFilter {
        case .sent:
            return "Historique des PC envoyés"
        default:
            return "Gestion rapide des statuts PC"
        }
    }

    private var headerCounters: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(PCHeaderFilter.allCases, id: \.self) { filter in
                let count = viewModel.headerCounts[filter, default: 0]
                Button {
                    viewModel.selectedHeaderFilter = filter
                    if filter == .sent {
                        exportURL = makeCSVFile(records: viewModel.sentHistory)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(count)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                        Text(filter.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(color(for: filter))
                    .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(viewModel.selectedHeaderFilter == filter ? color(for: filter).opacity(0.24) : AppColor.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(viewModel.selectedHeaderFilter == filter ? color(for: filter).opacity(0.58) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColor.surface.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(4)
    }

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Section header
            HStack {
                Text("Filtres")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                let isActive = viewModel.selectedParcType != "Tous"
                    || viewModel.selectedBrand != "Tous"
                    || viewModel.selectedModel != "Tous"
                    || viewModel.selectedZone != "Tous"
                    || !viewModel.searchQuery.isEmpty
                if isActive {
                    Button {
                        viewModel.selectedParcType = "Tous"
                        viewModel.selectedBrand = "Tous"
                        viewModel.selectedModel = "Tous"
                        viewModel.selectedZone = "Tous"
                        viewModel.searchQuery = ""
                    } label: {
                        Text("Réinitialiser")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.danger)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.searchQuery.isEmpty
                && viewModel.selectedParcType == "Tous"
                && viewModel.selectedBrand == "Tous"
                && viewModel.selectedModel == "Tous"
                && viewModel.selectedZone == "Tous")

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(viewModel.searchQuery.isEmpty ? AppColor.textTertiary : AppColor.brand)
                TextField("Rechercher hostname, référence…", text: $viewModel.searchQuery)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 12)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(viewModel.searchQuery.isEmpty ? Color.white.opacity(0.08) : AppColor.brand.opacity(0.35), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: viewModel.searchQuery.isEmpty)

            // Filter rows — iOS Settings style
            VStack(spacing: 0) {
                filterMenuRow(title: "Type de parc", selection: $viewModel.selectedParcType, options: viewModel.parcTypes)
                dividerInset
                filterMenuRow(title: "Constructeur", selection: $viewModel.selectedBrand, options: viewModel.brands)
                dividerInset
                filterMenuRow(title: "Modèle", selection: $viewModel.selectedModel, options: viewModel.models)
                dividerInset
                filterMenuRow(title: "Zone de stockage", selection: $viewModel.selectedZone, options: viewModel.zones)
            }
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            loadingCard
        } else if let errorMessage = viewModel.errorMessage {
            errorCard(errorMessage)
        } else if viewModel.selectedHeaderFilter == .sent {
            sentHistorySection
        } else if viewModel.filteredPCs.isEmpty {
            emptyCard
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("PC")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)

                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.filteredPCs) { article in
                        pcCard(article)
                    }
                }
            }
        }
    }

    private var sentHistorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Historique envoyé")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColor.textPrimary)

            if viewModel.sentHistory.isEmpty {
                emptySentHistoryCard
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.sentHistory) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row.hostname)
                                .font(.headline)
                                .foregroundStyle(AppColor.textPrimary)
                            Text("\(row.model) • \(row.destinationAgency)")
                                .font(.subheadline)
                                .foregroundStyle(AppColor.textSecondary)
                            Text("Destinataire: \(row.recipientName)")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                            Text(row.sentAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(AppColor.textTertiary)
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func pcCard(_ article: Article) -> some View {
        let status = PCStatus.from(description: article.descriptionText)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.surface)
                        .frame(width: 40, height: 40)
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(article.name)
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Asset: \(article.reference)")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    Text("\(article.brand ?? "-") \(article.model ?? "")")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text(status.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color(for: status).opacity(0.2))
                    .foregroundStyle(color(for: status))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                statusActionButton(
                    title: "Envoyé",
                    icon: "paperplane.fill",
                    color: AppColor.danger,
                    filled: true,
                    isDisabled: !viewModel.canSend(article)
                ) {
                    selectedForSend = article
                }

                statusActionButton(
                    title: "Disponible",
                    icon: "checkmark.circle",
                    color: AppColor.brand,
                    filled: false,
                    isDisabled: !viewModel.canMarkAvailable(article)
                ) {
                    viewModel.markAvailable(article: article, technician: technicianName.isEmpty ? "Technicien" : technicianName)
                }

                statusActionButton(
                    title: "A chaud",
                    icon: "flame.fill",
                    color: AppColor.success,
                    filled: false,
                    isDisabled: !viewModel.canMarkHot(article)
                ) {
                    viewModel.markHot(article: article, technician: technicianName.isEmpty ? "Technicien" : technicianName)
                }
            }
            .font(.caption)
        }
        .padding(AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func statusActionButton(
        title: String,
        icon: String,
        color: Color,
        filled: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
                .foregroundStyle(filled ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(filled ? color.opacity(isDisabled ? 0.35 : 1.0) : color.opacity(0.16))
                )
                .overlay(
                    Capsule()
                        .stroke(color.opacity(filled ? 0 : 0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
    }

    private func sendSheet(article: Article) -> some View {
        NavigationStack {
            ZStack {
                AppColor.pageGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        sheetHeader(
                            title: "Marquer envoyé",
                            subtitle: "Valider l'expédition du PC"
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("PC sélectionné")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                            Text(article.name)
                                .font(.headline)
                                .foregroundStyle(AppColor.textPrimary)
                            Text("Asset: \(article.reference)")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                        formTextField("Agence EDS destination", text: $destinationAgency)
                        formTextField("Nom destinataire", text: $recipientName)
                        formTextField("Nom technicien", text: $technicianName)
                    }
                    .padding(AppSpacing.md)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button("Annuler") {
                        selectedForSend = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button("Valider") {
                        viewModel.send(
                            article: article,
                            destinationAgency: destinationAgency,
                            recipientName: recipientName,
                            technician: technicianName.isEmpty ? "Technicien" : technicianName
                        )
                        destinationAgency = ""
                        recipientName = ""
                        selectedForSend = nil
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColor.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .opacity(destinationAgency.isEmpty || recipientName.isEmpty ? 0.45 : 1.0)
                    .disabled(destinationAgency.isEmpty || recipientName.isEmpty)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, 10)
                .padding(.bottom, AppSpacing.md)
                .background(.ultraThinMaterial.opacity(0.8))
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func sheetHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private func formTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private func filterMenuRow(title: String, selection: Binding<String>, options: [String]) -> some View {
        let isActive = selection.wrappedValue != "Tous"
        return HStack(spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        HStack {
                            Text(option)
                            if selection.wrappedValue == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.wrappedValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isActive ? AppColor.brand : AppColor.textSecondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isActive ? AppColor.brand : AppColor.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? AppColor.brand.opacity(0.12) : Color.clear)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
    }

    private var dividerInset: some View {
        Divider()
            .background(Color.white.opacity(0.08))
            .padding(.leading, AppSpacing.md)
    }

    private var loadingCard: some View {
        VStack(spacing: 10) {
            ProgressView().tint(AppColor.brand)
            Text("Chargement du parc PC...")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColor.danger)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                Task { await viewModel.reload(siteId: container.selectedSite?.id) }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColor.brand)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 36))
                .foregroundStyle(AppColor.textSecondary)
            Text("Aucun PC trouvé")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text("Change les filtres ou ajoute un nouveau PC")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private var emptySentHistoryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(AppColor.textSecondary)
            Text("Aucun envoi enregistré")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text("Les envois validés apparaîtront ici")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func color(for filter: PCHeaderFilter) -> Color {
        switch filter {
        case .hot: return AppColor.success
        case .rework: return AppColor.warning
        case .machining: return Color(red: 0.85, green: 0.45, blue: 0.1)
        case .available: return AppColor.brand
        case .sent: return AppColor.danger
        }
    }

    private func color(for status: PCStatus) -> Color {
        switch status {
        case .hot: return AppColor.success
        case .rework: return AppColor.warning
        case .machining: return Color(red: 0.85, green: 0.45, blue: 0.1)
        case .available: return AppColor.brand
        case .sent: return AppColor.danger
        case .unknown: return .secondary
        }
    }

    private func makeCSVFile(records: [PCSentHistoryRecord]) -> URL? {
        var csv = "hostname,modele,agence_destination,destinataire,date\n"
        let formatter = ISO8601DateFormatter()
        for row in records {
            let line = [
                row.hostname,
                row.model,
                row.destinationAgency,
                row.recipientName,
                formatter.string(from: row.sentAt)
            ].map(escapeCSV).joined(separator: ",")
            csv += line + "\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pc_envoyes_\(Int(Date().timeIntervalSince1970)).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
