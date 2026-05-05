import Foundation

struct CreateArticleUseCase: Sendable {
    private let repository: ArticleRepository

    init(repository: ArticleRepository) {
        self.repository = repository
    }

    func execute(_ input: NewArticleInput, photoJPEGData: Data?) async throws -> Article {
        try await repository.createArticle(input: input, photoJPEGData: photoJPEGData)
    }
}
