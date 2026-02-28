import Foundation
import Combine
import Network

@MainActor
final class PollingService: ObservableObject {
    static let shared = PollingService()

    @Published var repoStatuses: [String: CIStatus] = [:]
    @Published var aggregateStatus: CIStatus = .unknown
    @Published var lastUpdated: Date?
    @Published var isPolling = false
    @Published var error: String?

    private var pollingTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = true

    private init() {
        startNetworkMonitoring()
    }

    var pollingInterval: TimeInterval {
        UserDefaults.standard.double(forKey: Constants.UserDefaultsKeys.pollingInterval)
            .clamped(to: Constants.Defaults.minPollingInterval...Constants.Defaults.maxPollingInterval,
                     default: Constants.Defaults.pollingInterval)
    }

    var monitoredRepos: [MonitoredRepo] {
        RepoStore.shared.repos
    }

    func startPolling() {
        stopPolling()
        isPolling = true
        pollingTask = Task {
            while !Task.isCancelled {
                await poll()
                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }

    func refreshNow() {
        Task { await poll() }
    }

    private func poll() async {
        guard isNetworkAvailable else {
            error = "Network unavailable"
            return
        }

        let repos = monitoredRepos
        guard !repos.isEmpty else {
            repoStatuses = [:]
            aggregateStatus = .unknown
            error = nil
            return
        }

        let previousStatuses = repoStatuses
        let results = await GitHubAPIService.shared.fetchAllStatuses(repos: repos)

        repoStatuses = results
        aggregateStatus = CIStatus.aggregate(Array(results.values))
        lastUpdated = Date()
        error = nil

        // Notify on status transitions
        for (repoID, newStatus) in results {
            if let oldStatus = previousStatuses[repoID], oldStatus != newStatus {
                NotificationService.shared.notifyStatusChange(
                    repoID: repoID, from: oldStatus, to: newStatus
                )
            }
        }
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = path.status == .satisfied
                if path.status == .satisfied {
                    self?.error = nil
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}

// MARK: - Repo Persistence

@MainActor
final class RepoStore: ObservableObject {
    static let shared = RepoStore()

    @Published var repos: [MonitoredRepo] = []

    private init() {
        load()
    }

    func add(_ repo: MonitoredRepo) {
        guard !repos.contains(where: { $0.id == repo.id }) else { return }
        repos.append(repo)
        save()
    }

    func remove(at offsets: IndexSet) {
        repos.remove(atOffsets: offsets)
        save()
    }

    func remove(_ repo: MonitoredRepo) {
        repos.removeAll { $0.id == repo.id }
        save()
    }

    func addBranch(to repoID: String, branch: String) {
        guard let index = repos.firstIndex(where: { $0.id == repoID }) else { return }
        guard !repos[index].branches.contains(branch) else { return }
        repos[index].branches.append(branch)
        save()
    }

    func removeBranch(from repoID: String, branch: String) {
        guard let index = repos.firstIndex(where: { $0.id == repoID }) else { return }
        repos[index].branches.removeAll { $0 == branch }
        if repos[index].branches.isEmpty {
            repos.remove(at: index)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(repos) {
            UserDefaults.standard.set(data, forKey: Constants.UserDefaultsKeys.monitoredRepos)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.monitoredRepos),
              let decoded = try? JSONDecoder().decode([MonitoredRepo].self, from: data)
        else { return }
        repos = decoded
    }
}

// MARK: - Clamped helper

private extension Double {
    func clamped(to range: ClosedRange<Double>, default defaultValue: Double) -> Double {
        if self < range.lowerBound || self > range.upperBound {
            return defaultValue
        }
        return self == 0 ? defaultValue : self
    }
}
