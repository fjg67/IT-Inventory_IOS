import XCTest
@testable import ItInventory

final class FetchArticlesUseCaseTests: XCTestCase {
    func testExecuteReturnsRepositoryValues() async throws {
        let repo = MockArticleRepository(items: [
            Article(
                id: UUID(),
                reference: "1100005",
                name: "Keyboard",
                category: "Input",
                brand: "Logitech",
                barcode: "123",
                unit: "Pcs",
                minStock: 5,
                imageURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ])

        let useCase = FetchArticlesUseCase(repository: repo)
        let result = try await useCase.execute(search: nil)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.reference, "1100005")
    }
}

private struct MockArticleRepository: ArticleRepository {
    let items: [Article]

    func fetchArticles(search: String?) async throws -> [Article] {
        items
    }

    func fetchArticlesPage(offset: Int, limit: Int, includeArchived: Bool) async throws -> [Article] {
        let filtered = includeArchived ? items : items.filter { !$0.isArchived }
        guard offset < filtered.count else { return [] }
        let end = min(filtered.count, offset + limit)
        return Array(filtered[offset..<end])
    }

    func findArticle(barcode: String) async throws -> Article? {
        items.first { $0.barcode == barcode }
    }

    func createArticle(input: NewArticleInput, photoJPEGData: Data?) async throws -> Article {
        Article(
            id: UUID(),
            reference: input.reference,
            name: input.name,
            descriptionText: input.descriptionText,
            category: input.category,
            brand: input.brand,
            model: input.model,
            barcode: input.barcode,
            unit: input.unit,
            minStock: input.minStock,
            imageURL: nil,
            isArchived: false,
            articleType: input.articleType,
            codeFamille: input.codeFamille,
            emplacement: input.emplacement,
            sousType: input.sousType,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateArticlePCMetadata(
        articleID: UUID,
        descriptionText: String,
        codeFamille: String,
        isArchived: Bool
    ) async throws -> Article {
        items.first { $0.id == articleID } ?? items[0]
    }

    func createPCArticle(
        hostname: String,
        assetNumber: String,
        statusDescription: String,
        codeFamille: String,
        parcType: String,
        brand: String,
        model: String
    ) async throws -> Article {
        Article(
            id: UUID(),
            reference: assetNumber,
            name: hostname,
            descriptionText: "Statut: A chaud",
            category: "PC",
            brand: brand,
            model: model,
            barcode: nil,
            unit: "Pcs",
            minStock: 0,
            imageURL: nil,
            isArchived: false,
            articleType: "PC",
            codeFamille: "PC portable",
            emplacement: nil,
            sousType: parcType,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
