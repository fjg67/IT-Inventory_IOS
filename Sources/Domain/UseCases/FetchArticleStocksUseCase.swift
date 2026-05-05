import Foundation

struct FetchArticleStocksUseCase: Sendable {
    private let repository: ArticleStockRepository

    init(repository: ArticleStockRepository) {
        self.repository = repository
    }

    func execute(forArticle articleId: UUID) async throws -> [ArticleStock] {
        try await repository.fetchStocks(forArticle: articleId)
    }
}
