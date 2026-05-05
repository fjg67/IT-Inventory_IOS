import Foundation

struct MovementRepositoryImpl: MovementRepository {
    private let remote: MovementsRemoteDataSource

    init(remote: MovementsRemoteDataSource) {
        self.remote = remote
    }

    func fetchMovements(limit: Int) async throws -> [StockMovement] {
        try await remote.fetchMovements(limit: limit)
    }

    func fetchMovementsPage(offset: Int, limit: Int) async throws -> [StockMovement] {
        try await remote.fetchMovementsPage(offset: offset, limit: limit)
    }

    func fetchMovements(forArticle articleId: UUID) async throws -> [StockMovement] {
        try await remote.fetchMovements(forArticle: articleId)
    }

    func fetchMovements(forSite siteId: String, limit: Int) async throws -> [StockMovement] {
        try await remote.fetchMovements(forSite: siteId, limit: limit)
    }

    func fetchMovementsPage(forSite siteId: String, offset: Int, limit: Int) async throws -> [StockMovement] {
        try await remote.fetchMovementsPage(forSite: siteId, offset: offset, limit: limit)
    }

    func countMovements(forSite siteId: String, type: MovementType?) async throws -> Int {
        try await remote.countMovements(forSite: siteId, type: type)
    }

    func createMovement(_ movement: NewStockMovement) async throws {
        try await remote.createMovement(movement)
    }
}
