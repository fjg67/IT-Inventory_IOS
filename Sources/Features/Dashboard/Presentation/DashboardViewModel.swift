import Foundation

@Observable
final class DashboardViewModel: @unchecked Sendable {
    var greeting: String = greetingForCurrentHour()
    var activeArticleCount = 0
    var totalStock = 0
    var lowStockAlertCount = 0
    var todayMovementCount = 0
    var isLoading = false
    var errorMessage: String?

    var trend: [KPITrendPoint] = []
    var recentMovements: [RecentMovementItem] = []

    private let fetchArticlesUseCase: FetchArticlesUseCase
    private let fetchMovementsUseCase: FetchMovementsUseCase
    private let articleStockRepository: ArticleStockRepository

    init(
        fetchArticlesUseCase: FetchArticlesUseCase,
        fetchMovementsUseCase: FetchMovementsUseCase,
        articleStockRepository: ArticleStockRepository
    ) {
        self.fetchArticlesUseCase = fetchArticlesUseCase
        self.fetchMovementsUseCase = fetchMovementsUseCase
        self.articleStockRepository = articleStockRepository
        self.trend = Self.emptyTrend()
    }

    func loadOnAppear(siteId: String?) {
        Task { await reload(siteId: siteId) }
    }

    func reload(siteId: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let articlesTask = fetchArticlesUseCase.execute(search: nil)
            let articles = try await articlesTask

            let movements: [StockMovement]
            let stocks: [ArticleStock]
            if let siteId {
                async let movTask = fetchMovementsUseCase.execute(forSite: siteId, limit: 500)
                async let stkTask = articleStockRepository.fetchAllStocks(forSite: siteId)
                movements = try await movTask
                stocks = try await stkTask
            } else {
                async let movTask = fetchMovementsUseCase.execute(limit: 500)
                async let stkTask = articleStockRepository.fetchAllStocks()
                movements = try await movTask
                stocks = try await stkTask
            }

            // KPI 1 – articles with stock at this site (or all active if no site)
            let articleMap = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
            if siteId != nil {
                let articlesWithStock = Set(stocks.filter { $0.quantity > 0 }.map { $0.articleId })
                activeArticleCount = articlesWithStock.count
            } else {
                activeArticleCount = articles.filter { !$0.isArchived }.count
            }

            // KPI 2 – total stock
            totalStock = stocks.reduce(0) { $0 + $1.quantity }

            // KPI 3 – low stock alerts
            let stockByArticle = Dictionary(grouping: stocks, by: \.articleId)
                .mapValues { $0.reduce(0) { $0 + $1.quantity } }
            lowStockAlertCount = articles.filter { article in
                guard article.minStock > 0 else { return false }
                return (stockByArticle[article.id] ?? 0) < article.minStock
            }.count

            // KPI 4 – movements today
            let calendar = Calendar.current
            todayMovementCount = movements.filter {
                calendar.isDateInToday($0.createdAt)
            }.count

            // Recent movements – last 5
            recentMovements = movements
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)
                .map { mov in
                    let article = articleMap[mov.articleId]
                    return RecentMovementItem(
                        id: mov.id,
                        type: mov.type,
                        quantity: mov.quantity,
                        articleName: article?.name ?? "Article #\(mov.articleId.uuidString.prefix(8))",
                        articleReference: article?.reference ?? "-",
                        createdAt: mov.createdAt
                    )
                }

            // Weekly trend – last 7 days
            trend = buildWeeklyTrend(movements: movements)
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
    }

    // MARK: – Helpers

    private func buildWeeklyTrend(movements: [StockMovement]) -> [KPITrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayNames = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]

        return (0..<7).reversed().map { offset -> KPITrendPoint in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return KPITrendPoint(day: "-", value: 0)
            }
            let count = movements.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count
            let weekday = calendar.component(.weekday, from: day) - 1
            return KPITrendPoint(day: dayNames[weekday], value: count)
        }
    }

    private static func emptyTrend() -> [KPITrendPoint] {
        ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"].map {
            KPITrendPoint(day: $0, value: 0)
        }
    }
}

struct KPITrendPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Int

}

private func greetingForCurrentHour() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12: return "Bonjour"
    case 12..<18: return "Bon après-midi"
    default: return "Bonsoir"
    }
}

