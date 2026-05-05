import XCTest
@testable import ItInventory

final class SignInUseCaseTests: XCTestCase {
    func testExecuteThrowsValidationErrorWhenEmailIsEmpty() async {
        let useCase = SignInUseCase(repository: AuthRepositoryMock())

        do {
            _ = try await useCase.execute(email: "", password: "pwd")
            XCTFail("Expected validation error")
        } catch let error as AppError {
            XCTAssertEqual(error, .validation(message: "Email et mot de passe requis"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteReturnsSessionWhenCredentialsValid() async throws {
        let expected = AuthSession(
            userID: "user-1",
            email: "user@test.com",
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )

        let useCase = SignInUseCase(repository: AuthRepositoryMock(session: expected))
        let result = try await useCase.execute(email: "user@test.com", password: "pwd")

        XCTAssertEqual(result, expected)
    }
}

private struct AuthRepositoryMock: AuthRepository {
    var session: AuthSession?

    init(session: AuthSession? = nil) {
        self.session = session
    }

    func restoreSession() async throws -> AuthSession? {
        session
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        if let session {
            return session
        }

        throw AppError.unknown
    }

    func signOut() async throws {}
}
