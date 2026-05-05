import Foundation

protocol MovementRepository: Sendable {
    func fetchMovements(limit: Int) async throws -> [StockMovement]
    func fetchMovementsPage(offset: Int, limit: Int) async throws -> [StockMovement]
    func fetchMovements(forArticle articleId: UUID) async throws -> [StockMovement]
    func fetchMovements(forSite siteId: String, limit: Int) async throws -> [StockMovement]
    func fetchMovementsPage(forSite siteId: String, offset: Int, limit: Int) async throws -> [StockMovement]
    func countMovements(forSite siteId: String, type: MovementType?) async throws -> Int
    func createMovement(_ movement: NewStockMovement) async throws
}
