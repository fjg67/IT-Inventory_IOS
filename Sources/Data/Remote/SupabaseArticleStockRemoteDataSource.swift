import Foundation
import Supabase

protocol ArticleStockRemoteDataSource: Sendable {
    func fetchStocks(forArticle articleId: UUID) async throws -> [ArticleStock]
    func fetchAllStocks() async throws -> [ArticleStock]
    func fetchAllStocks(forSite siteId: String) async throws -> [ArticleStock]
}

struct SupabaseArticleStockRemoteDataSource: ArticleStockRemoteDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchStocks(forArticle articleId: UUID) async throws -> [ArticleStock] {
        let items: [ArticleStockDTO] = try await client
            .from("ArticleStock")
            .select("id,articleId,siteId,quantity")
            .eq("articleId", value: articleId.uuidString.lowercased())
            .execute()
            .value
        return items.map { $0.toDomain() }
    }

    func fetchAllStocks() async throws -> [ArticleStock] {
        let items: [ArticleStockDTO] = try await client
            .from("ArticleStock")
            .select("id,articleId,siteId,quantity")
            .execute()
            .value
        return items.map { $0.toDomain() }
    }

    func fetchAllStocks(forSite siteId: String) async throws -> [ArticleStock] {
        let items: [ArticleStockDTO] = try await client
            .from("ArticleStock")
            .select("id,articleId,siteId,quantity")
            .eq("siteId", value: siteId)
            .execute()
            .value
        return items.map { $0.toDomain() }
    }
}
