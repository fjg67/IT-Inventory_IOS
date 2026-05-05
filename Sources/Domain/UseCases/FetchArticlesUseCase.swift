import Foundation

struct FetchArticlesUseCase {
    private let repository: any ArticleRepository

    init(repository: any ArticleRepository) {
        self.repository = repository
    }

    func execute(search: String?) async throws -> [Article] {
        try await repository.fetchArticles(search: search)
    }

    func executePage(offset: Int, limit: Int, includeArchived: Bool) async throws -> [Article] {
        try await repository.fetchArticlesPage(offset: offset, limit: limit, includeArchived: includeArchived)
    }
}
