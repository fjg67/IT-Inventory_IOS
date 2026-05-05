import Foundation

struct SignInUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> AuthSession {
        guard !email.isEmpty, !password.isEmpty else {
            throw AppError.validation(message: "Email et mot de passe requis")
        }

        return try await repository.signIn(email: email, password: password)
    }
}
