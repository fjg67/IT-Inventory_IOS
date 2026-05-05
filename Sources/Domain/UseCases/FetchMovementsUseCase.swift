import Foundation

struct FetchMovementsUseCase: Sendable {
    private let repository: MovementRepository

    init(repository: MovementRepository) {
        self.repository = repository
    }

    func execute(limit: Int = 200) async throws -> [StockMovement] {
        try await repository.fetchMovements(limit: limit)
    }

    func executePage(offset: Int, limit: Int) async throws -> [StockMovement] {
        try await repository.fetchMovementsPage(offset: offset, limit: limit)
    }

    func execute(forArticle articleId: UUID) async throws -> [StockMovement] {
        try await repository.fetchMovements(forArticle: articleId)
    }

    func execute(forSite siteId: String, limit: Int = 200) async throws -> [StockMovement] {
        try await repository.fetchMovements(forSite: siteId, limit: limit)
    }

    func executePage(forSite siteId: String, offset: Int, limit: Int) async throws -> [StockMovement] {
        try await repository.fetchMovementsPage(forSite: siteId, offset: offset, limit: limit)
    }

    func countMovements(forSite siteId: String, type: MovementType? = nil) async throws -> Int {
        try await repository.countMovements(forSite: siteId, type: type)
    }
}

struct CreateStockMovementUseCase: Sendable {
    private let repository: MovementRepository

    init(repository: MovementRepository) {
        self.repository = repository
    }

    func execute(_ movement: NewStockMovement) async throws {
        try await repository.createMovement(movement)
    }
}
