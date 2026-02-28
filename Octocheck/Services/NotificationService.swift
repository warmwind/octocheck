import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyStatusChange(repoID: String, from oldStatus: CIStatus, to newStatus: CIStatus) {
        let enabled = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Octocheck"
        content.body = "\(repoID): \(oldStatus.label) → \(newStatus.label)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(repoID)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
