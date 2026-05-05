import Foundation

struct ArticleStockRow: Identifiable, Sendable {
    let id: String
    let siteName: String
    let quantity: Int
}

@Observable
final class ArticleStockViewModel: @unchecked Sendable {
    var stockRows: [ArticleStockRow] = []
    var recentMovements: [MovementRow] = []
    var isLoading = false
    var errorMessage: String?
    var movementSuccessMessage: String? = nil

    private let article: Article
    private let fetchArticleStocksUseCase: FetchArticleStocksUseCase
    private let articleStockRepository: ArticleStockRepository
    private let fetchMovementsUseCase: FetchMovementsUseCase
    private let siteRepository: SiteRepository
    private let createStockMovementUseCase: CreateStockMovementUseCase
    private let stockMovementNotificationService: StockMovementNotificationService
    let selectedSiteId: String?

    init(
        article: Article,
        fetchArticleStocksUseCase: FetchArticleStocksUseCase,
        articleStockRepository: ArticleStockRepository,
        fetchMovementsUseCase: FetchMovementsUseCase,
        siteRepository: SiteRepository,
        createStockMovementUseCase: CreateStockMovementUseCase,
        stockMovementNotificationService: StockMovementNotificationService,
        selectedSiteId: String?
    ) {
        self.article = article
        self.fetchArticleStocksUseCase = fetchArticleStocksUseCase
        self.articleStockRepository = articleStockRepository
        self.fetchMovementsUseCase = fetchMovementsUseCase
        self.siteRepository = siteRepository
        self.createStockMovementUseCase = createStockMovementUseCase
        self.stockMovementNotificationService = stockMovementNotificationService
        self.selectedSiteId = selectedSiteId
    }

    func loadOnAppear() {
        Task { await reload() }
    }

    func createMovement(
        type: MovementType,
        quantity: Int,
        reason: String?,
        technicianId: String,
        technicianName: String,
        targetSiteId: String? = nil
    ) async throws {
        let fromSiteId: String?
        let toSiteId: String?
        switch type {
        case .entry:
            fromSiteId = nil
            toSiteId = selectedSiteId
        case .exit:
            fromSiteId = selectedSiteId
            toSiteId = nil
        case .adjustment:
            fromSiteId = selectedSiteId
            toSiteId = nil
        case .transfer:
            fromSiteId = selectedSiteId
            toSiteId = targetSiteId
        case .unknown:
            return
        }
        try await createStockMovementUseCase.execute(
            NewStockMovement(
                type: type,
                quantity: quantity,
                reason: reason,
                articleId: article.id,
                fromSiteId: fromSiteId,
                toSiteId: toSiteId,
                userId: technicianId
            )
        )

        let sites = try await siteRepository.fetchAllSites()
        let fromSiteName = sites.first(where: { $0.id == fromSiteId })?.name
        let toSiteName = sites.first(where: { $0.id == toSiteId })?.name
        stockMovementNotificationService.notifyMovement(
            type: type,
            quantity: quantity,
            articleName: article.name,
            siteSourceName: fromSiteName,
            siteDestinationName: toSiteName,
            technicianName: technicianName
        )

        NotificationCenter.default.post(name: .stockMovementCreated, object: nil)
        await reload()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let movementsTask = fetchMovementsUseCase.execute(forArticle: article.id)
            async let sitesTask = siteRepository.fetchAllSites()

            let stocks: [ArticleStock]
            if let selectedSiteId {
                stocks = try await articleStockRepository
                    .fetchAllStocks(forSite: selectedSiteId)
                    .filter { $0.articleId == article.id }
            } else {
                stocks = try await fetchArticleStocksUseCase.execute(forArticle: article.id)
            }

            let (movements, sites) = try await (movementsTask, sitesTask)

            let siteMap = Dictionary(uniqueKeysWithValues: sites.map { ($0.id, $0.name) })

            stockRows = stocks.map { stock in
                ArticleStockRow(
                    id: stock.id,
                    siteName: siteMap[stock.siteId] ?? stock.siteId,
                    quantity: stock.quantity
                )
            }.sorted { $0.quantity > $1.quantity }

            recentMovements = movements
                .filter { movement in
                    guard let selectedSiteId else { return true }
                    let fromMatches = movement.fromSiteId == selectedSiteId
                    let toMatches = movement.toSiteId == selectedSiteId
                    return fromMatches || toMatches
                }
                .map { movement in
                MovementRow(
                    id: UUID(),
                    type: movement.type,
                    quantity: movement.quantity,
                    reason: movement.reason,
                    articleName: article.name,
                    articleReference: article.reference,
                    fromSiteName: movement.fromSiteId.flatMap { siteMap[$0] } ?? movement.fromSiteId ?? "-",
                    toSiteName: movement.toSiteId.flatMap { siteMap[$0] },
                    createdAt: movement.createdAt,
                    technicianInitials: "?"
                )
            }
        } catch {
            errorMessage = "Impossible de charger le stock."
        }
    }

}
