import Foundation
import LocalAuthentication

@Observable
final class AuthViewModel: @unchecked Sendable {
    enum Status: Equatable {
        case checking
        case unauthenticated
        case authenticated(AuthSession)
    }

    var status: Status = .checking
    var password = ""
    var errorMessage: String?
    var isSubmitting = false
    var isBiometricEnabled = false
    var loginSucceeded = false

    private let restoreSessionUseCase: RestoreSessionUseCase
    private let signInUseCase: SignInUseCase
    private let signOutUseCase: SignOutUseCase
    private let biometricKey = "security.biometric.enabled"
    private let localLoginKey = "auth.local.loggedIn"
    private let appPassword = "!*A1Z2E3R4T5!"

    init(
        restoreSessionUseCase: RestoreSessionUseCase,
        signInUseCase: SignInUseCase,
        signOutUseCase: SignOutUseCase
    ) {
        self.restoreSessionUseCase = restoreSessionUseCase
        self.signInUseCase = signInUseCase
        self.signOutUseCase = signOutUseCase
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricKey)
    }

    func bootstrap() async {
        status = .checking

        do {
            if let session = try await restoreSessionUseCase.execute() {
                status = .authenticated(session)
                return
            }
        } catch {
            // Fallback to local persisted auth flag.
        }

        if UserDefaults.standard.bool(forKey: localLoginKey) {
            status = .authenticated(
                AuthSession(
                    userID: "local-user",
                    email: "local@app",
                    accessToken: "local",
                    refreshToken: "local",
                    expiresAt: .distantFuture
                )
            )
        } else {
            status = .unauthenticated
        }
    }

    func bootstrapIfNeeded() {
        guard case .checking = status else {
            return
        }

        Task {
            await bootstrap()
        }
    }

    func signInButtonTapped() {
        Task {
            await signIn()
        }
    }

    func signOutButtonTapped() {
        Task {
            await signOut()
        }
    }

    func signIn() async {
        errorMessage = nil
        isSubmitting = true

        if password == appPassword {
            loginSucceeded = true
            isSubmitting = false
            try? await Task.sleep(for: .milliseconds(700))
            UserDefaults.standard.set(true, forKey: localLoginKey)
            status = .authenticated(
                AuthSession(
                    userID: "local-user",
                    email: "local@app",
                    accessToken: "local",
                    refreshToken: "local",
                    expiresAt: .distantFuture
                )
            )
            password = ""
            loginSucceeded = false
        } else {
            isSubmitting = false
            errorMessage = "Mot de passe incorrect."
            status = .unauthenticated
        }
    }

    func signOut() async {
        errorMessage = nil
        password = ""
        UserDefaults.standard.set(false, forKey: localLoginKey)
        status = .unauthenticated
    }

    func signInWithBiometrics() {
        guard isBiometricEnabled else { return }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Se connecter à IT Inventory"
        ) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.loginSucceeded = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(700))
                        await MainActor.run {
                            UserDefaults.standard.set(true, forKey: self.localLoginKey)
                            self.status = .authenticated(
                                AuthSession(
                                    userID: "local-user",
                                    email: "local@app",
                                    accessToken: "local",
                                    refreshToken: "local",
                                    expiresAt: .distantFuture
                                )
                            )
                            self.loginSucceeded = false
                        }
                    }
                }
            }
        }
    }

    func setBiometricEnabled(_ enabled: Bool) {
        guard enabled else {
            isBiometricEnabled = false
            UserDefaults.standard.set(false, forKey: biometricKey)
            return
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "Face ID / Touch ID non disponible sur cet appareil."
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Activer le verrouillage biométrique"
        ) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.isBiometricEnabled = true
                    UserDefaults.standard.set(true, forKey: self.biometricKey)
                } else {
                    self.isBiometricEnabled = false
                    UserDefaults.standard.set(false, forKey: self.biometricKey)
                }
            }
        }
    }
}

private extension AppError {
    var userMessage: String {
        switch self {
        case .networkUnavailable:
            return "Aucune connexion reseau."
        case .unauthorized:
            return "Session non autorisee."
        case .forbidden:
            return "Action interdite."
        case .notFound:
            return "Ressource introuvable."
        case .conflict:
            return "Conflit de donnees detecte."
        case .validation(let message):
            return message
        case .unknown:
            return "Erreur inattendue."
        }
    }
}
