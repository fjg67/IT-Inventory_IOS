import Foundation

struct MovementRow: Identifiable, Sendable {
    let id: UUID
    let type: MovementType
    let quantity: Int
    let reason: String?
    let articleName: String
    let articleReference: String
    let fromSiteName: String
    let toSiteName: String?
    let createdAt: Date
    let technicianInitials: String
}

@Observable
final class MovementsViewModel: @unchecked Sendable {
    var rows: [MovementRow] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMorePages = true
    var errorMessage: String?
    var selectedType: MovementType?
    var totalCount: Int?
    var countByType: [MovementType: Int] = [:]

    var filtered: [MovementRow] {
        guard let type = selectedType else { return rows }
        return rows.filter { $0.type == type }
    }

    private let fetchMovementsUseCase: FetchMovementsUseCase
    private let fetchArticlesUseCase: FetchArticlesUseCase
    private let siteRepository: SiteRepository
    private let technicianRepository: TechnicianRepository
    private let pageSize = 80
    private var currentOffset = 0
    private var articleMap: [UUID: Article] = [:]
    private var siteMap: [String: String] = [:]
    private var technicianMap: [String: String] = [:]
    private var currentSiteId: String?

    var selectedTotalCount: Int {
        if let selectedType {
            return countByType[selectedType] ?? filtered.count
        }
        return totalCount ?? filtered.count
    }

    init(
        fetchMovementsUseCase: FetchMovementsUseCase,
        fetchArticlesUseCase: FetchArticlesUseCase,
        siteRepository: SiteRepository,
        technicianRepository: TechnicianRepository
    ) {
        self.fetchMovementsUseCase = fetchMovementsUseCase
        self.fetchArticlesUseCase = fetchArticlesUseCase
        self.siteRepository = siteRepository
        self.technicianRepository = technicianRepository
    }

    func loadOnAppear(siteId: String?) {
        currentSiteId = siteId
        Task { await reload() }
    }

    func loadMoreIfNeeded(currentRowID: UUID) {
        guard hasMorePages, !isLoading, !isLoadingMore else { return }
        guard let lastID = filtered.last?.id, lastID == currentRowID else { return }

        Task { await loadNextPage() }
    }

    func reload() async {
        currentOffset = 0
        hasMorePages = true
        rows = []
        totalCount = nil
        countByType = [:]

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let movementsTask: [StockMovement] = {
                if let siteId = currentSiteId {
                    return try await fetchMovementsUseCase.executePage(forSite: siteId, offset: 0, limit: pageSize)
                } else {
                    return try await fetchMovementsUseCase.executePage(offset: 0, limit: pageSize)
                }
            }()
            async let countTask: Int? = {
                if let siteId = currentSiteId {
                    return try await fetchMovementsUseCase.countMovements(forSite: siteId)
                }
                return nil
            }()
            async let entryCountTask: Int? = {
                guard let siteId = currentSiteId else { return nil }
                return try await fetchMovementsUseCase.countMovements(forSite: siteId, type: .entry)
            }()
            async let exitCountTask: Int? = {
                guard let siteId = currentSiteId else { return nil }
                return try await fetchMovementsUseCase.countMovements(forSite: siteId, type: .exit)
            }()
            async let adjustmentCountTask: Int? = {
                guard let siteId = currentSiteId else { return nil }
                return try await fetchMovementsUseCase.countMovements(forSite: siteId, type: .adjustment)
            }()
            async let transferCountTask: Int? = {
                guard let siteId = currentSiteId else { return nil }
                return try await fetchMovementsUseCase.countMovements(forSite: siteId, type: .transfer)
            }()
            async let articlesTask = fetchArticlesUseCase.execute(search: nil)
            async let sitesTask = siteRepository.fetchAllSites()
            async let techniciansTask = technicianRepository.fetchActiveTechnicians()

            let counts = try await (
                countTask,
                entryCountTask,
                exitCountTask,
                adjustmentCountTask,
                transferCountTask
            )
            let (movements, articles, sites, technicians) = try await (
                movementsTask,
                articlesTask,
                sitesTask,
                techniciansTask
            )

            articleMap = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
            siteMap = Dictionary(uniqueKeysWithValues: sites.map { ($0.id, $0.name) })
            technicianMap = Dictionary(uniqueKeysWithValues: technicians.map { ($0.id, $0.initials) })

            rows = mapRows(from: movements)
            currentOffset = movements.count
            hasMorePages = movements.count == pageSize
            totalCount = counts.0
            countByType = [
                .entry: counts.1 ?? rows.filter { $0.type == .entry }.count,
                .exit: counts.2 ?? rows.filter { $0.type == .exit }.count,
                .adjustment: counts.3 ?? rows.filter { $0.type == .adjustment }.count,
                .transfer: counts.4 ?? rows.filter { $0.type == .transfer }.count
            ]
        } catch {
            errorMessage = "Impossible de charger les mouvements."
            rows = []
        }
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page: [StockMovement]
            if let siteId = currentSiteId {
                page = try await fetchMovementsUseCase.executePage(forSite: siteId, offset: currentOffset, limit: pageSize)
            } else {
                page = try await fetchMovementsUseCase.executePage(offset: currentOffset, limit: pageSize)
            }
            currentOffset += page.count
            hasMorePages = page.count == pageSize
            rows.append(contentsOf: mapRows(from: page))
        } catch {
            errorMessage = "Impossible de charger plus de mouvements."
            hasMorePages = false
        }
    }

    private func mapRows(from movements: [StockMovement]) -> [MovementRow] {
        movements.compactMap { movement in
            let article = articleMap[movement.articleId]
            let initials = technicianMap[movement.userId] ?? initialsFromId(movement.userId)
            return MovementRow(
                id: UUID(uuidString: movement.id) ?? UUID(),
                type: movement.type,
                quantity: movement.quantity,
                reason: movement.reason,
                articleName: article?.name ?? "Article inconnu",
                articleReference: article?.reference ?? "-",
                fromSiteName: movement.fromSiteId.flatMap { siteMap[$0] } ?? movement.fromSiteId ?? "-",
                toSiteName: movement.toSiteId.flatMap { siteMap[$0] },
                createdAt: movement.createdAt,
                technicianInitials: initials
            )
        }
    }

    private func initialsFromId(_ id: String) -> String {
        String(id.prefix(2)).uppercased()
    }
}
