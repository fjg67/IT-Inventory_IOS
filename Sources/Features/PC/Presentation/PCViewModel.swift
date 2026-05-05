import Foundation

@Observable
final class PCViewModel: @unchecked Sendable {
    var isLoading = false
    var errorMessage: String?

    var selectedHeaderFilter: PCHeaderFilter = .hot

    var selectedParcType: String = "Tous"
    var selectedBrand: String = "Tous"
    var selectedModel: String = "Tous"
    var selectedZone: String = "Tous"
    var searchQuery: String = ""

    var createDraft = PCCreateDraft()

    private(set) var activePCs: [Article] = []
    private(set) var sentHistory: [PCSentHistoryRecord] = []

    private let articleRepository: ArticleRepository
    private let articleStockRepository: ArticleStockRepository
    private let historyStore: PCSentHistoryStore
    private let notificationService: PCStatusNotificationService
    private var currentSiteId: String?

    init(
        articleRepository: ArticleRepository,
        articleStockRepository: ArticleStockRepository,
        historyStore: PCSentHistoryStore,
        notificationService: PCStatusNotificationService
    ) {
        self.articleRepository = articleRepository
        self.articleStockRepository = articleStockRepository
        self.historyStore = historyStore
        self.notificationService = notificationService
    }

    var headerCounts: [PCHeaderFilter: Int] {
        [
            .hot: count(status: .hot),
            .rework: count(status: .rework),
            .machining: count(status: .machining),
            .available: count(status: .available),
            .sent: sentHistory.count
        ]
    }

    var filteredPCs: [Article] {
        guard selectedHeaderFilter != .sent else { return [] }

        return activePCs.filter { article in
            guard matchesHeader(article) else { return false }
            guard selectedParcType == "Tous" || (article.sousType ?? "") == selectedParcType else { return false }
            guard selectedBrand == "Tous" || (article.brand ?? "") == selectedBrand else { return false }
            guard selectedModel == "Tous" || (article.model ?? "") == selectedModel else { return false }
            guard selectedZone == "Tous" || (article.emplacement ?? "") == selectedZone else { return false }
            if !searchQuery.isEmpty {
                let query = searchQuery.lowercased()
                guard article.name.lowercased().contains(query)
                    || article.reference.lowercased().contains(query)
                    || (article.brand ?? "").lowercased().contains(query)
                    || (article.model ?? "").lowercased().contains(query)
                else { return false }
            }
            return true
        }
    }

    var parcTypes: [String] {
        options(from: activePCs.compactMap { $0.sousType })
    }

    var brands: [String] {
        options(from: activePCs.compactMap { $0.brand })
    }

    var models: [String] {
        options(from: activePCs.compactMap { $0.model })
    }

    var zones: [String] {
        options(from: activePCs.compactMap { $0.emplacement })
    }

    func loadOnAppear(siteId: String?) {
        Task { await reload(siteId: siteId) }
    }

    func reload(siteId: String?) async {
        isLoading = true
        errorMessage = nil
        currentSiteId = siteId
        defer { isLoading = false }

        do {
            let articles = try await articleRepository.fetchArticles(search: nil)

            if let siteId {
                let stocks = try await articleStockRepository.fetchAllStocks(forSite: siteId)
                let articleIDsInSite = Set(stocks.filter { $0.quantity > 0 }.map { $0.articleId })
                activePCs = articles.filter { article in
                    isPCArticle(article) && articleIDsInSite.contains(article.id)
                }
            } else {
                activePCs = articles.filter(isPCArticle)
            }

            sentHistory = historyStore.fetch()
            notificationService.notifyAgingAvailabilityIfNeeded(records: activePCs, thresholdDays: 21)
        } catch {
            errorMessage = "Impossible de charger le parc PC."
        }
    }

    func markHot(article: Article, technician: String) {
        Task {
            await updateStatus(
                article: article,
                status: .hot,
                codeFamille: PCStatus.hot.familyValue,
                isArchived: false,
                technician: technician
            )
        }
    }

    func markAvailable(article: Article, technician: String) {
        Task {
            await updateStatus(
                article: article,
                status: .available,
                codeFamille: PCStatus.available.familyValue,
                isArchived: false,
                technician: technician
            )
        }
    }

    func send(
        article: Article,
        destinationAgency: String,
        recipientName: String,
        technician: String
    ) {
        Task {
            do {
                let updated = try await articleRepository.updateArticlePCMetadata(
                    articleID: article.id,
                    descriptionText: PCStatus.sent.descriptionValue,
                    codeFamille: PCStatus.sent.familyValue,
                    isArchived: true
                )

                let record = PCSentHistoryRecord(
                    id: UUID(),
                    articleID: updated.id,
                    hostname: updated.name,
                    model: updated.model ?? "-",
                    destinationAgency: destinationAgency,
                    recipientName: recipientName,
                    sentAt: Date(),
                    technicianName: technician
                )
                historyStore.add(record)
                notificationService.notifyStatusChange(technician: technician, status: .sent, hostname: updated.name)
                await reload(siteId: currentSiteId)
            } catch {
                errorMessage = "Impossible de marquer ce PC comme envoye."
            }
        }
    }

    @MainActor
    func createPC(draft: PCCreateDraft) async -> Bool {
        let cleanedHostname = draft.hostname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAsset = draft.assetNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedModel = draft.model.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedHostname.isEmpty, !cleanedAsset.isEmpty, !cleanedModel.isEmpty else {
            errorMessage = "Compléter hostname, asset et modèle."
            return false
        }

        do {
            _ = try await articleRepository.createPCArticle(
                hostname: cleanedHostname,
                assetNumber: cleanedAsset,
                statusDescription: draft.status.descriptionValue,
                codeFamille: draft.status.familyValue,
                parcType: draft.parcType,
                brand: draft.brand,
                model: cleanedModel
            )
            createDraft = PCCreateDraft()
            await reload(siteId: currentSiteId)
            return true
        } catch {
            let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if message.isEmpty {
                errorMessage = "Impossible de créer le PC dans Supabase."
            } else {
                errorMessage = "Impossible de créer le PC dans Supabase: \(message)"
            }
            return false
        }
    }

    func addQuickPC() {
        Task { _ = await createPC(draft: createDraft) }
    }

    func canSend(_ article: Article) -> Bool {
        let status = PCStatus.from(description: article.descriptionText)
        return status == .hot || status == .available
    }

    func canMarkHot(_ article: Article) -> Bool {
        let status = PCStatus.from(description: article.descriptionText)
        return status == .rework || status == .machining || status == .available
    }

    func canMarkAvailable(_ article: Article) -> Bool {
        let status = PCStatus.from(description: article.descriptionText)
        return status == .rework || status == .machining || status == .hot
    }

    private func count(status: PCStatus) -> Int {
        activePCs.filter { PCStatus.from(description: $0.descriptionText) == status }.count
    }

    private func matchesHeader(_ article: Article) -> Bool {
        let status = PCStatus.from(description: article.descriptionText)
        switch selectedHeaderFilter {
        case .hot: return status == .hot
        case .rework: return status == .rework
        case .machining: return status == .machining
        case .available: return status == .available
        case .sent: return false
        }
    }

    private func updateStatus(
        article: Article,
        status: PCStatus,
        codeFamille: String,
        isArchived: Bool,
        technician: String
    ) async {
        do {
            let updated = try await articleRepository.updateArticlePCMetadata(
                articleID: article.id,
                descriptionText: status.descriptionValue,
                codeFamille: codeFamille,
                isArchived: isArchived
            )
            notificationService.notifyStatusChange(technician: technician, status: status, hostname: updated.name)
            await reload(siteId: currentSiteId)
        } catch {
            errorMessage = "Impossible de changer le statut."
        }
    }

    private func isPCArticle(_ article: Article) -> Bool {
        let type = (article.articleType ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return type.contains("pc")
    }

    private func options(from values: [String]) -> [String] {
        let unique = Set(values.filter { !$0.isEmpty }).sorted()
        return ["Tous"] + unique
    }
}
