import Foundation

enum ScanState: Equatable {
    case idle
    case searching
    case found(Article)
    case notFound(String)
    case articleNotFound(String)   // barcode existe mais aucun article en DB
    case permissionDenied
}

struct ScanStockLookupResult {
    let quantity: Int?
    let existsOnSelectedSite: Bool
}

@Observable
final class ScanViewModel: @unchecked Sendable {
    var state: ScanState = .idle
    var mode: ScanMode = .consultation
    var sites: [Site] = []

    private let findArticleByBarcodeUseCase: FindArticleByBarcodeUseCase
    private let articleRepository: ArticleRepository
    private let createStockMovementUseCase: CreateStockMovementUseCase
    private let stockMovementNotificationService: StockMovementNotificationService
    private let pcStatusNotificationService: PCStatusNotificationService
    private let articleStockRepository: ArticleStockRepository
    private let siteRepository: SiteRepository

    init(
        findArticleByBarcodeUseCase: FindArticleByBarcodeUseCase,
        articleRepository: ArticleRepository,
        createStockMovementUseCase: CreateStockMovementUseCase,
        stockMovementNotificationService: StockMovementNotificationService,
        pcStatusNotificationService: PCStatusNotificationService,
        articleStockRepository: ArticleStockRepository,
        siteRepository: SiteRepository
    ) {
        self.findArticleByBarcodeUseCase = findArticleByBarcodeUseCase
        self.articleRepository = articleRepository
        self.createStockMovementUseCase = createStockMovementUseCase
        self.stockMovementNotificationService = stockMovementNotificationService
        self.pcStatusNotificationService = pcStatusNotificationService
        self.articleStockRepository = articleStockRepository
        self.siteRepository = siteRepository
    }

    @MainActor
    func updatePCStatus(article: Article, status: PCStatus, technicianName: String?) async -> (Bool, String?) {
        let currentStatus = PCStatus.from(description: article.descriptionText)
        guard currentStatus != status else {
            return (false, nil)
        }

        do {
            let updated = try await articleRepository.updateArticlePCMetadata(
                articleID: article.id,
                descriptionText: status.descriptionValue,
                codeFamille: status.familyValue,
                isArchived: status == .sent
            )
            pcStatusNotificationService.notifyStatusChange(
                technician: technicianName ?? "Technicien",
                status: status,
                hostname: updated.name
            )
            state = .idle
            return (true, nil)
        } catch {
            print("❌ updatePCStatus error: \(error)")
            state = .notFound(error.localizedDescription)
            return (false, error.localizedDescription)
        }
    }

    func currentStock(for articleId: UUID, siteId: String?) async -> ScanStockLookupResult {
        guard let siteId else {
            return ScanStockLookupResult(quantity: nil, existsOnSelectedSite: true)
        }

        do {
            let stocks = try await articleStockRepository.fetchStocks(forArticle: articleId)
            if let stock = stocks.first(where: { $0.siteId == siteId }) {
                return ScanStockLookupResult(quantity: stock.quantity, existsOnSelectedSite: true)
            }
            return ScanStockLookupResult(quantity: 0, existsOnSelectedSite: false)
        } catch {
            return ScanStockLookupResult(quantity: nil, existsOnSelectedSite: true)
        }
    }

    func onBarcode(_ code: String) {
        switch state {
        case .idle, .notFound, .articleNotFound:
            break
        case .searching, .found, .permissionDenied:
            return
        }

        state = .searching

        Task {
            do {
                if let article = try await findArticleByBarcodeUseCase.execute(barcode: code) {
                    await MainActor.run {
                        state = .found(article)
                    }
                } else {
                    await MainActor.run {
                        state = .articleNotFound(code)
                    }
                }
            } catch {
                await MainActor.run {
                    state = .notFound("Erreur lors de la recherche.")
                }
            }
        }
    }

    func reset() {
        state = .idle
    }

    func loadSitesOnAppear() {
        guard sites.isEmpty else { return }
        Task {
            do {
                sites = try await siteRepository.fetchAllSites().filter { $0.isActive }
            } catch {
                // Keep empty list to avoid blocking scan flow.
            }
        }
    }

    func transferTargets(excluding currentSiteId: String?) -> [Site] {
        guard let currentSiteId else { return sites }
        return sites.filter { $0.id != currentSiteId }
    }

    @MainActor
    func createMovement(
        article: Article,
        type: MovementType,
        quantity: Int,
        reason: String?,
        selectedSiteId: String?,
        technicianId: String?,
        technicianName: String?,
        targetSiteId: String? = nil
    ) async {
        guard let selectedSiteId else {
            state = .notFound("Sélectionne un site avant de créer un mouvement.")
            return
        }
        guard let technicianId else {
            state = .notFound("Sélectionne un technicien avant de créer un mouvement.")
            return
        }

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
            guard let targetSiteId else {
                state = .notFound("Choisis un site de destination pour le transfert.")
                return
            }
            fromSiteId = selectedSiteId
            toSiteId = targetSiteId
        case .unknown:
            state = .notFound("Type de mouvement invalide.")
            return
        }

        do {
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

            let fromSiteName = sites.first(where: { $0.id == fromSiteId })?.name
            let toSiteName = sites.first(where: { $0.id == toSiteId })?.name
            stockMovementNotificationService.notifyMovement(
                type: type,
                quantity: quantity,
                articleName: article.name,
                siteSourceName: fromSiteName,
                siteDestinationName: toSiteName,
                technicianName: technicianName ?? "Technicien inconnu"
            )

            NotificationCenter.default.post(name: .stockMovementCreated, object: nil)
            state = .idle
        } catch {
            state = .notFound("Erreur : \(error.localizedDescription)")
        }
    }
}
