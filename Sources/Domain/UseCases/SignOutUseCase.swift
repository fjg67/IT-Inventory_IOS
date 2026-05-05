import Foundation

struct SignOutUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.signOut()
    }
}
