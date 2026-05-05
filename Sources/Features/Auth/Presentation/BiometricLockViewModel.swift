import Foundation
import LocalAuthentication

@Observable
final class BiometricLockViewModel: @unchecked Sendable {
    var isLocked = false
    var isBiometricAvailable = false
    var isUnlocking = false
    var errorMessage: String?

    init() {
        refreshAvailability()
    }

    func refreshAvailability() {
        var error: NSError?
        isBiometricAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func lock() {
        refreshAvailability()
        guard isBiometricAvailable else { return }
        isLocked = true
        errorMessage = nil
    }

    func unlockIfNeeded() {
        guard isLocked else { return }
        unlock()
    }

    func unlock() {
        guard isBiometricAvailable else {
            isLocked = false
            return
        }

        isUnlocking = true
        errorMessage = nil

        let freshContext = LAContext()
        let reason = "Déverrouiller It-Inventory"
        freshContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isUnlocking = false
                if success {
                    self.isLocked = false
                } else {
                    self.isLocked = true
                    self.errorMessage = error?.localizedDescription ?? "Échec de l'authentification biométrique."
                }
            }
        }
    }

    func reset() {
        isLocked = false
        isUnlocking = false
        errorMessage = nil
    }
}
