import SwiftUI
import Combine

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var repoStatuses: [String: CIStatus] = [:]
    @Published var aggregateStatus: CIStatus = .unknown
    @Published var lastUpdated: Date?
    @Published var error: String?

    private var cancellables = Set<AnyCancellable>()
    private let pollingService = PollingService.shared
    private let repoStore = RepoStore.shared

    var repos: [MonitoredRepo] {
        repoStore.repos
    }

    init() {
        pollingService.$repoStatuses
            .assign(to: &$repoStatuses)
        pollingService.$aggregateStatus
            .assign(to: &$aggregateStatus)
        pollingService.$lastUpdated
            .assign(to: &$lastUpdated)
        pollingService.$error
            .assign(to: &$error)
    }

    func status(for repo: MonitoredRepo) -> CIStatus {
        repoStatuses[repo.id] ?? .unknown
    }

    func refreshNow() {
        pollingService.refreshNow()
    }

    func openInGitHub(_ repo: MonitoredRepo) {
        if let url = repo.actionsURL {
            NSWorkspace.shared.open(url)
        }
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
