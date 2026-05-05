import Foundation

enum ArticleStockLevel {
    case good
    case warning
    case critical
}

enum ArticlesSortMode: String, CaseIterable {
    case newest = "Nouveaux"
    case alphabetical = "A-Z"
    case reference = "Reference"
}

@Observable
final class ArticlesViewModel: @unchecked Sendable {
    var query = ""
    var selectedCategory: String? = nil
    var sortMode: ArticlesSortMode = .newest
    var isLoading = false
    var isLoadingMore = false
    var hasMorePages = true
    var errorMessage: String?
    private(set) var articles: [Article] = []
    private(set) var imageFallbackByReference: [String: URL] = [:]
    private(set) var stockByArticleId: [UUID: Int] = [:]
    private(set) var scopedArticleIds: Set<UUID>? = nil

    var visibleArticles: [Article] {
        let filteredByCategory = articles.filter { article in
            if let selectedCategory {
                return article.category == selectedCategory
            }
            return true
        }

        let filteredWithoutExcludedDevices = filteredByCategory.filter { !isExcludedDeviceArticle($0) }
        let filteredBySelectedSubSite: [Article]
        if let scopedArticleIds {
            filteredBySelectedSubSite = filteredWithoutExcludedDevices.filter { scopedArticleIds.contains($0.id) }
        } else {
            filteredBySelectedSubSite = filteredWithoutExcludedDevices
        }

        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        guard !normalizedQuery.isEmpty else {
            return sortArticles(filteredBySelectedSubSite)
        }

        let searched = filteredBySelectedSubSite.filter { article in
            let haystack = [
                article.reference,
                article.name,
                article.category ?? "",
                article.brand ?? "",
                article.model ?? "",
                article.barcode ?? ""
            ]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

            return haystack.contains(normalizedQuery)
        }

        return sortArticles(searched)
    }

    private let fetchArticlesUseCase: FetchArticlesUseCase
    private let articleStockRepository: ArticleStockRepository
    private let pageSize = 50
    private var currentOffset = 0
    private var loadedSiteId: String?

    init(fetchArticlesUseCase: FetchArticlesUseCase, articleStockRepository: ArticleStockRepository) {
        self.fetchArticlesUseCase = fetchArticlesUseCase
        self.articleStockRepository = articleStockRepository
    }

    func loadOnAppear(siteId: String?) {
        guard articles.isEmpty || loadedSiteId != siteId else { return }
        Task {
            await reload(siteId: siteId)
        }
    }

    func queryDidChange() {
    }

    func sortModeDidChange() {
    }

    var uniqueCategories: [String] {
        let categories = Set(articles.compactMap { $0.category })
        return categories.sorted()
    }

    func displayImageURL(for article: Article) -> URL? {
        article.imageURL ?? imageFallbackByReference[article.reference]
    }

    func stockQuantity(for article: Article) -> Int {
        stockByArticleId[article.id] ?? 0
    }

    func stockLevel(for article: Article) -> ArticleStockLevel {
        let quantity = stockQuantity(for: article)
        if quantity <= 0 {
            return .critical
        }
        if article.minStock > 0, quantity <= article.minStock {
            return .warning
        }
        return .good
    }

    func reload(siteId: String?) async {
        loadedSiteId = siteId
        currentOffset = 0
        hasMorePages = true
        articles = []
        imageFallbackByReference = [:]
        stockByArticleId = [:]
        scopedArticleIds = nil

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let stocksTask: [ArticleStock]
        do {
            if let siteId {
                stocksTask = try await articleStockRepository.fetchAllStocks(forSite: siteId)
            } else {
                stocksTask = try await articleStockRepository.fetchAllStocks()
            }
        } catch {
            stocksTask = []
        }

        await loadAllPages()

        stockByArticleId = Dictionary(
            stocksTask.map { ($0.articleId, $0.quantity) },
            uniquingKeysWith: +
        )
        if siteId != nil {
            scopedArticleIds = Set(stocksTask.map(\.articleId))
        } else {
            scopedArticleIds = nil
        }
    }

    private func loadAllPages() async {
        while hasMorePages {
            await loadNextPage()
        }
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchArticlesUseCase.executePage(
                offset: currentOffset,
                limit: pageSize,
                includeArchived: true
            )

            currentOffset += page.count
            hasMorePages = page.count == pageSize
            articles.append(contentsOf: page)
            rebuildImageFallbackIndex()
        } catch {
            errorMessage = "Impossible de charger les articles."
            hasMorePages = false
        }
    }

    private func rebuildImageFallbackIndex() {
        var index: [String: URL] = [:]
        for article in articles {
            guard let imageURL = article.imageURL else { continue }
            if index[article.reference] == nil {
                index[article.reference] = imageURL
            }
        }
        imageFallbackByReference = index
    }

    private func isExcludedDeviceArticle(_ article: Article) -> Bool {
        let normalizedType = (article.articleType ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedType == "pc" || normalizedType == "tablette" || normalizedType == "tablet" {
            return true
        }

        let normalizedCategory = (article.category ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedCategory == "pc" || normalizedCategory == "tablette" || normalizedCategory == "tablet" {
            return true
        }

        let normalizedFamily = (article.codeFamille ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedFamily.contains("pc") || normalizedFamily.contains("tablette") || normalizedFamily.contains("tablet") {
            return true
        }

        let normalizedSubType = (article.sousType ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedSubType.contains("tablette") || normalizedSubType.contains("tablet")
    }

    private func sortArticles(_ articles: [Article]) -> [Article] {
        switch sortMode {
        case .newest:
            return articles.sorted { $0.updatedAt > $1.updatedAt }
        case .alphabetical:
            return articles.sorted {
                $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    < $1.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            }
        case .reference:
            return articles.sorted {
                $0.reference.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    < $1.reference.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            }
        }
    }
}
