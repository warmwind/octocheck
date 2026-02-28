import SwiftUI
import Combine

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var repoStatuses: [String: CIStatus] = [:]
    @Published var aggregateStatus: CIStatus = .unknown
    @Published var lastUpdated: Date?
    @Published var error: String?

    @Published var repos: [MonitoredRepo] = []

    private let pollingService = PollingService.shared
    private let repoStore = RepoStore.shared

    init() {
        repos = repoStore.repos
        repoStore.$repos
            .assign(to: &$repos)
        pollingService.$repoStatuses
            .assign(to: &$repoStatuses)
        pollingService.$aggregateStatus
            .assign(to: &$aggregateStatus)
        pollingService.$lastUpdated
            .assign(to: &$lastUpdated)
        pollingService.$error
            .assign(to: &$error)
    }

    func status(for repo: MonitoredRepo, branch: String) -> CIStatus {
        repoStatuses[repo.statusKey(branch: branch)] ?? .unknown
    }

    func refreshNow() {
        pollingService.refreshNow()
    }

    func openInGitHub(_ repo: MonitoredRepo, branch: String) {
        if let url = repo.actionsURL(branch: branch) {
            NSWorkspace.shared.open(url)
        }
    }

    struct RepoBranchRow: Identifiable {
        let id: String
        let repo: MonitoredRepo
        let branch: String
    }

    var repoBranchRows: [RepoBranchRow] {
        repos.flatMap { repo in
            repo.branches.map { branch in
                RepoBranchRow(id: repo.statusKey(branch: branch), repo: repo, branch: branch)
            }
        }
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
