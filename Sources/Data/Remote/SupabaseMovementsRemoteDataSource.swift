import Foundation
import Supabase

protocol MovementsRemoteDataSource: Sendable {
    func fetchMovements(limit: Int) async throws -> [StockMovement]
    func fetchMovementsPage(offset: Int, limit: Int) async throws -> [StockMovement]
    func fetchMovements(forArticle articleId: UUID) async throws -> [StockMovement]
    func fetchMovements(forSite siteId: String, limit: Int) async throws -> [StockMovement]
    func fetchMovementsPage(forSite siteId: String, offset: Int, limit: Int) async throws -> [StockMovement]
    func countMovements(forSite siteId: String, type: MovementType?) async throws -> Int
    func createMovement(_ movement: NewStockMovement) async throws
}

struct SupabaseMovementsRemoteDataSource: MovementsRemoteDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchMovements(limit: Int) async throws -> [StockMovement] {
        try await fetchMovementsPage(offset: 0, limit: limit)
    }

    func fetchMovementsPage(offset: Int, limit: Int) async throws -> [StockMovement] {
        let from = max(0, offset)
        let to = max(0, offset + max(1, limit) - 1)

        let items: [StockMovementDTO] = try await client
            .from("StockMovement")
            .select("id,type,quantity,reason,articleId,fromSiteId,toSiteId,userId,createdAt")
            .order("createdAt", ascending: false)
            .range(from: from, to: to)
            .execute()
            .value
        return items.map { $0.toDomain() }
    }

    func fetchMovements(forArticle articleId: UUID) async throws -> [StockMovement] {
        let items: [StockMovementDTO] = try await client
            .from("StockMovement")
            .select("id,type,quantity,reason,articleId,fromSiteId,toSiteId,userId,createdAt")
            .eq("articleId", value: articleId.uuidString)
            .order("createdAt", ascending: false)
            .limit(50)
            .execute()
            .value
        return items.map { $0.toDomain() }
    }

    func fetchMovements(forSite siteId: String, limit: Int) async throws -> [StockMovement] {
        let items: [StockMovementDTO] = try await client
            .from("StockMovement")
            .select("id,type,quantity,reason,articleId,fromSiteId,toSiteId,userId,createdAt")
            .eq("fromSiteId", value: siteId)
            .order("createdAt", ascending: false)
            .limit(limit)
            .execute()
            .value
        return items.map { $0.toDomain() }
    }

    func fetchMovementsPage(forSite siteId: String, offset: Int, limit: Int) async throws -> [StockMovement] {
        let from = max(0, offset)
        let to = max(0, offset + max(1, limit) - 1)
        let items: [StockMovementDTO] = try await client
            .from("StockMovement")
            .select("id,type,quantity,reason,articleId,fromSiteId,toSiteId,userId,createdAt")
            .eq("fromSiteId", value: siteId)
            .order("createdAt", ascending: false)
            .range(from: from, to: to)
            .execute()
            .value
        return items.map { $0.toDomain() }
    }

    func countMovements(forSite siteId: String, type: MovementType?) async throws -> Int {
        var query = client
            .from("StockMovement")
            .select("*", head: true, count: .exact)
            .eq("fromSiteId", value: siteId)

        if let type {
            query = query.eq("type", value: type.rawValue)
        }

        let response = try await query.execute()
        return response.count ?? 0
    }

    func createMovement(_ movement: NewStockMovement) async throws {
        let payload = NewStockMovementDTO(
            id: UUID().uuidString.lowercased(),
            type: movement.type.rawValue,
            quantity: movement.quantity,
            reason: movement.reason,
            articleId: movement.articleId.uuidString.lowercased(),
            fromSiteId: movement.fromSiteId,
            toSiteId: movement.toSiteId,
            userId: movement.userId
        )

        try await client
            .from("StockMovement")
            .insert(payload)
            .execute()
    }
}

private struct NewStockMovementDTO: Encodable {
    let id: String
    let type: String
    let quantity: Int
    let reason: String?
    let articleId: String
    let fromSiteId: String?
    let toSiteId: String?
    let userId: String
}
