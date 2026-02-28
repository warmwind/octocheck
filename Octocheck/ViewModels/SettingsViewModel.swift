import SwiftUI
import ServiceManagement

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var token: String = ""
    @Published var validatedUser: String?
    @Published var isValidating = false
    @Published var tokenError: String?

    @Published var newRepoInput: String = "" // "owner/name" format
    @Published var isAddingRepo = false
    @Published var repoError: String?

    @Published var pollingInterval: Double = Constants.Defaults.pollingInterval
    @Published var launchAtLogin = false
    @Published var notificationsEnabled = true

    private let repoStore = RepoStore.shared

    var repos: [MonitoredRepo] {
        repoStore.repos
    }

    init() {
        // Load existing token presence (don't show the actual token)
        if KeychainService.shared.loadPAT() != nil {
            validatedUser = "Authenticated" // Will be updated on validate
        }
        pollingInterval = UserDefaults.standard.double(forKey: Constants.UserDefaultsKeys.pollingInterval)
        if pollingInterval == 0 { pollingInterval = Constants.Defaults.pollingInterval }
        launchAtLogin = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.launchAtLogin)
        notificationsEnabled = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        if !UserDefaults.standard.contains(key: Constants.UserDefaultsKeys.notificationsEnabled) {
            notificationsEnabled = true
        }
    }

    func saveAndValidateToken() {
        guard !token.isEmpty else {
            tokenError = "Token cannot be empty"
            return
        }

        isValidating = true
        tokenError = nil

        Task {
            do {
                try KeychainService.shared.savePAT(token)
                let username = try await GitHubAPIService.shared.validateToken()
                validatedUser = username
                token = "" // Clear from memory
                tokenError = nil

                // Start polling after successful auth
                PollingService.shared.startPolling()
            } catch {
                validatedUser = nil
                tokenError = error.localizedDescription
            }
            isValidating = false
        }
    }

    func removeToken() {
        try? KeychainService.shared.deletePAT()
        validatedUser = nil
        token = ""
        PollingService.shared.stopPolling()
    }

    func addRepo() {
        let input = newRepoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = input.split(separator: "/")
        guard parts.count == 2 else {
            repoError = "Enter repo as owner/name"
            return
        }

        let owner = String(parts[0])
        let name = String(parts[1])
        isAddingRepo = true
        repoError = nil

        Task {
            do {
                let repoInfo = try await GitHubAPIService.shared.fetchRepoInfo(owner: owner, name: name)
                let repo = MonitoredRepo(
                    owner: owner,
                    name: name,
                    defaultBranch: repoInfo.defaultBranch
                )
                repoStore.add(repo)
                newRepoInput = ""
                repoError = nil
                // Trigger a refresh
                PollingService.shared.refreshNow()
            } catch {
                repoError = error.localizedDescription
            }
            isAddingRepo = false
        }
    }

    func removeRepo(_ repo: MonitoredRepo) {
        repoStore.remove(repo)
    }

    func removeRepos(at offsets: IndexSet) {
        repoStore.remove(at: offsets)
    }

    func savePollingInterval() {
        UserDefaults.standard.set(pollingInterval, forKey: Constants.UserDefaultsKeys.pollingInterval)
        // Restart polling with new interval
        if PollingService.shared.isPolling {
            PollingService.shared.startPolling()
        }
    }

    func toggleLaunchAtLogin() {
        UserDefaults.standard.set(launchAtLogin, forKey: Constants.UserDefaultsKeys.launchAtLogin)
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    func toggleNotifications() {
        UserDefaults.standard.set(notificationsEnabled, forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        if notificationsEnabled {
            NotificationService.shared.requestPermission()
        }
    }
}

// MARK: - UserDefaults helper

extension UserDefaults {
    func contains(key: String) -> Bool {
        object(forKey: key) != nil
    }
}
