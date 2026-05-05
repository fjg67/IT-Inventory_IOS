import Foundation

struct RestoreSessionUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute() async throws -> AuthSession? {
        try await repository.restoreSession()
    }
}
