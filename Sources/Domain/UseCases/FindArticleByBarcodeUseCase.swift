import Foundation

struct FindArticleByBarcodeUseCase: Sendable {
    private let repository: ArticleRepository

    init(repository: ArticleRepository) {
        self.repository = repository
    }

    func execute(barcode: String) async throws -> Article? {
        try await repository.findArticle(barcode: barcode)
    }
}
