import Foundation
import AppKit

final class NotificationService: NSObject {
    static let shared = NotificationService()
    private override init() { super.init() }

    func requestPermission() {
        // No permission needed for NSUserNotificationCenter
    }

    func notifyStatusChange(repoID: String, from oldStatus: CIStatus, to newStatus: CIStatus) {
        let enabled = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        guard enabled else { return }

        let notification = NSUserNotification()
        notification.title = "Octocheck"
        notification.informativeText = "\(repoID): \(oldStatus.label) → \(newStatus.label)"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
