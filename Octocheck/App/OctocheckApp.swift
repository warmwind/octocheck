import SwiftUI

@main
struct OctocheckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pollingService = PollingService.shared
    @StateObject private var repoStore = RepoStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            Image(systemName: pollingService.aggregateStatus.menuBarSymbol)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions (safe after app fully launched)
        NotificationService.shared.requestPermission()

        // Start polling if token exists
        if KeychainService.shared.loadPAT() != nil {
            Task { @MainActor in
                PollingService.shared.startPolling()
            }
        }
    }
}
