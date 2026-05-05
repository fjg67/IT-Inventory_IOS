import Foundation

protocol ArticleRepository: Sendable {
    func fetchArticles(search: String?) async throws -> [Article]
    func fetchArticlesPage(offset: Int, limit: Int, includeArchived: Bool) async throws -> [Article]
    func findArticle(barcode: String) async throws -> Article?
    func createArticle(input: NewArticleInput, photoJPEGData: Data?) async throws -> Article
    func updateArticlePCMetadata(
        articleID: UUID,
        descriptionText: String,
        codeFamille: String,
        isArchived: Bool
    ) async throws -> Article
    func createPCArticle(
        hostname: String,
        assetNumber: String,
        statusDescription: String,
        codeFamille: String,
        parcType: String,
        brand: String,
        model: String
    ) async throws -> Article
}
