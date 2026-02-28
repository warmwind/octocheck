import AppKit
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
            if pollingService.isLoading {
                Image(nsImage: coloredMenuBarImage(
                    systemName: "arrow.triangle.2.circlepath",
                    color: .systemOrange
                ))
            } else {
                let status = pollingService.aggregateStatus
                Image(nsImage: coloredMenuBarImage(
                    systemName: status.sfSymbol,
                    color: status.nsColor
                ))
            }
        }
        .menuBarExtraStyle(.window)

        Window("Octocheck Settings", id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 480, height: 360)
        .windowResizability(.contentSize)
    }
}

private func coloredMenuBarImage(systemName: String, color: NSColor) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
    let symbol = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!

    // Rasterize eagerly so the color is baked into actual pixels
    let image = NSImage(size: symbol.size)
    image.lockFocus()
    symbol.draw(in: NSRect(origin: .zero, size: symbol.size))
    color.set()
    NSRect(origin: .zero, size: symbol.size).fill(using: .sourceAtop)
    image.unlockFocus()

    image.isTemplate = false
    return image
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start polling if token exists
        if KeychainService.shared.loadPAT() != nil {
            Task { @MainActor in
                PollingService.shared.startPolling()
            }
        }
    }
}
