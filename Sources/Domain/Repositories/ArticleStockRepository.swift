import Foundation

protocol ArticleStockRepository: Sendable {
    func fetchStocks(forArticle articleId: UUID) async throws -> [ArticleStock]
    func fetchAllStocks() async throws -> [ArticleStock]
    func fetchAllStocks(forSite siteId: String) async throws -> [ArticleStock]
}
