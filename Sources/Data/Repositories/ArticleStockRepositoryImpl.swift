import Foundation

struct ArticleStockRepositoryImpl: ArticleStockRepository {
    private let remote: ArticleStockRemoteDataSource

    init(remote: ArticleStockRemoteDataSource) {
        self.remote = remote
    }

    func fetchStocks(forArticle articleId: UUID) async throws -> [ArticleStock] {
        try await remote.fetchStocks(forArticle: articleId)
    }

    func fetchAllStocks() async throws -> [ArticleStock] {
        try await remote.fetchAllStocks()
    }

    func fetchAllStocks(forSite siteId: String) async throws -> [ArticleStock] {
        try await remote.fetchAllStocks(forSite: siteId)
    }
}
