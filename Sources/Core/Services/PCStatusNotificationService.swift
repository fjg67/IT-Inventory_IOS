import Foundation
import UserNotifications

protocol PCStatusNotificationService {
    func notifyStatusChange(technician: String, status: PCStatus, hostname: String)
    func notifyAgingAvailabilityIfNeeded(records: [Article], thresholdDays: Int)
}

final class LocalPCStatusNotificationService: PCStatusNotificationService {
    private let center = UNUserNotificationCenter.current()

    init() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notifyStatusChange(technician: String, status: PCStatus, hostname: String) {
        let content = UNMutableNotificationContent()
        content.title = "PC: \(hostname)"
        content.body = "\(technician) a passe le statut a \(status.rawValue)."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    func notifyAgingAvailabilityIfNeeded(records: [Article], thresholdDays: Int) {
        let oldAvailable = records.filter {
            PCStatus.from(description: $0.descriptionText) == .available &&
            Calendar.current.dateComponents([.day], from: $0.updatedAt, to: Date()).day ?? 0 >= thresholdDays
        }

        guard !oldAvailable.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Alerte disponibilite PC"
        content.body = "\(oldAvailable.count) PC sont disponibles depuis plus de \(thresholdDays) jours."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "pc-availability-aging", content: content, trigger: trigger)
        center.add(request)
    }
}
