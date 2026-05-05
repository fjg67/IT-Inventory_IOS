import Foundation

@Observable
final class CreateMovementViewModel: @unchecked Sendable {

    // MARK: - Form state
    var selectedType: MovementType = .entry
    var selectedArticle: Article? = nil
    var articleSearch: String = ""
    var searchResults: [Article] = []
    var isSearching: Bool = false

    var fromSite: Site? = nil
    var toSite: Site? = nil
    var availableSites: [Site] = []

    var quantity: Int = 1
    var reason: String = ""

    var isSubmitting: Bool = false
    var errorMessage: String? = nil
    var didSucceed: Bool = false

    // MARK: - Dependencies
    private let createMovementUseCase: CreateStockMovementUseCase
    private let fetchArticlesUseCase: FetchArticlesUseCase
    private let siteRepository: SiteRepository
    private let stockMovementNotificationService: StockMovementNotificationService

    private var searchTask: Task<Void, Never>? = nil

    init(
        createMovementUseCase: CreateStockMovementUseCase,
        fetchArticlesUseCase: FetchArticlesUseCase,
        siteRepository: SiteRepository,
        stockMovementNotificationService: StockMovementNotificationService
    ) {
        self.createMovementUseCase = createMovementUseCase
        self.fetchArticlesUseCase = fetchArticlesUseCase
        self.siteRepository = siteRepository
        self.stockMovementNotificationService = stockMovementNotificationService
    }

    // MARK: - Load context

    func loadContext(defaultSite: Site?) async {
        do {
            let sites = try await siteRepository.fetchAllSites()
            await MainActor.run {
                self.availableSites = sites
                if let site = defaultSite ?? sites.first {
                    self.fromSite = site
                    self.toSite = site
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Impossible de charger les sites."
            }
        }
    }

    // MARK: - Article search

    func onArticleSearchChanged(_ query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        await MainActor.run { isSearching = true }
        do {
            let results = try await fetchArticlesUseCase.execute(search: query)
            await MainActor.run {
                self.searchResults = Array(results.prefix(20))
                self.isSearching = false
            }
        } catch {
            await MainActor.run { isSearching = false }
        }
    }

    func selectArticle(_ article: Article) {
        selectedArticle = article
        articleSearch = article.name
        searchResults = []
    }

    // MARK: - Validation

    var canSubmit: Bool {
        guard selectedArticle != nil, quantity > 0 else { return false }
        switch selectedType {
        case .entry:   return toSite != nil
        case .exit:    return fromSite != nil
        case .adjustment: return fromSite != nil
        case .transfer: return fromSite != nil && toSite != nil && fromSite?.id != toSite?.id
        case .unknown: return false
        }
    }

    // MARK: - Submit

    func submit(userId: String, technicianName: String) async {
        guard canSubmit, let article = selectedArticle else { return }

        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
        }

        let fromSiteId: String?
        let toSiteId: String?

        switch selectedType {
        case .entry:
            fromSiteId = nil
            toSiteId = toSite?.id
        case .exit:
            fromSiteId = fromSite?.id
            toSiteId = nil
        case .adjustment:
            fromSiteId = fromSite?.id
            toSiteId = nil
        case .transfer:
            fromSiteId = fromSite?.id
            toSiteId = toSite?.id
        case .unknown:
            fromSiteId = nil
            toSiteId = nil
        }

        let movement = NewStockMovement(
            type: selectedType,
            quantity: quantity,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : reason,
            articleId: article.id,
            fromSiteId: fromSiteId,
            toSiteId: toSiteId,
            userId: userId
        )

        do {
            try await createMovementUseCase.execute(movement)

            stockMovementNotificationService.notifyMovement(
                type: selectedType,
                quantity: quantity,
                articleName: article.name,
                siteSourceName: fromSite?.name,
                siteDestinationName: toSite?.name,
                technicianName: technicianName
            )

            await MainActor.run {
                isSubmitting = false
                didSucceed = true
            }
        } catch {
            await MainActor.run {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Reset

    func reset(defaultSite: Site?, preferredType: MovementType = .entry) {
        selectedType = preferredType
        selectedArticle = nil
        articleSearch = ""
        searchResults = []
        fromSite = defaultSite ?? availableSites.first
        toSite = defaultSite ?? availableSites.first
        quantity = 1
        reason = ""
        isSubmitting = false
        errorMessage = nil
        didSucceed = false
    }
}
