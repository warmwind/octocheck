import SwiftUI
import ServiceManagement
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    @Published var token: String = ""
    @Published var validatedUser: String?
    @Published var isValidating = false
    @Published var tokenError: String?

    @Published var availableRepos: [GitHubRepo] = []
    @Published var isLoadingRepos = false
    @Published var repoSearchText: String = ""
    @Published var repoError: String?

    @Published var repoBranches: [String: [GitHubBranch]] = [:]
    @Published var isLoadingBranches: [String: Bool] = [:]
    @Published var expandedRepos: Set<String> = []

    @Published var pollingInterval: Double = Constants.Defaults.pollingInterval
    @Published var launchAtLogin = false
    @Published var notificationsEnabled = true

    private let repoStore = RepoStore.shared
    private var repoStoreSubscription: AnyCancellable?

    @Published var repos: [MonitoredRepo] = []

    private init() {
        repos = repoStore.repos
        repoStoreSubscription = repoStore.$repos
            .assign(to: \.repos, on: self)
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

                // Start polling and load repos after successful auth
                PollingService.shared.startPolling()
                loadAvailableRepos()
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

    /// Repos filtered by search text, excluding already-monitored ones
    var filteredAvailableRepos: [GitHubRepo] {
        let monitoredIDs = Set(repos.map { $0.fullName })
        let unmonitored = availableRepos.filter { !monitoredIDs.contains($0.fullName) }
        guard !repoSearchText.isEmpty else { return unmonitored }
        return unmonitored.filter {
            $0.fullName.localizedCaseInsensitiveContains(repoSearchText)
        }
    }

    func loadAvailableRepos() {
        guard !isLoadingRepos else { return }
        isLoadingRepos = true
        repoError = nil

        Task {
            do {
                availableRepos = try await GitHubAPIService.shared.fetchUserRepos()
            } catch {
                repoError = error.localizedDescription
            }
            isLoadingRepos = false
        }
    }

    func addRepo(_ ghRepo: GitHubRepo) {
        let parts = ghRepo.fullName.split(separator: "/")
        guard parts.count == 2 else { return }
        let repo = MonitoredRepo(
            owner: String(parts[0]),
            name: String(parts[1]),
            branches: [ghRepo.defaultBranch]
        )
        repoStore.add(repo)
        PollingService.shared.refreshNow()
    }

    func removeRepo(_ repo: MonitoredRepo) {
        repoStore.remove(repo)
    }

    func removeRepos(at offsets: IndexSet) {
        repoStore.remove(at: offsets)
    }

    func addBranch(to repo: MonitoredRepo, branch: String) {
        repoStore.addBranch(to: repo.id, branch: branch)
        PollingService.shared.refreshNow()
    }

    func removeBranch(from repo: MonitoredRepo, branch: String) {
        repoStore.removeBranch(from: repo.id, branch: branch)
        PollingService.shared.refreshNow()
    }

    func updateWorkflowName(for repo: MonitoredRepo, workflowName: String) {
        let name = workflowName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        repoStore.updateWorkflowName(for: repo.id, workflowName: name)
        PollingService.shared.refreshNow()
    }

    func loadBranches(for repo: MonitoredRepo) {
        guard isLoadingBranches[repo.id] != true else { return }
        isLoadingBranches[repo.id] = true

        Task {
            do {
                let branches = try await GitHubAPIService.shared.fetchBranches(
                    owner: repo.owner, name: repo.name
                )
                repoBranches[repo.id] = branches
            } catch {
                repoError = error.localizedDescription
            }
            isLoadingBranches[repo.id] = false
        }
    }

    func availableBranches(for repo: MonitoredRepo) -> [GitHubBranch] {
        let tracked = Set(repo.branches)
        return (repoBranches[repo.id] ?? []).filter { !tracked.contains($0.name) }
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
