import Foundation

enum GitHubAPIError: LocalizedError {
    case noToken
    case invalidURL
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No GitHub token configured"
        case .invalidURL:
            return "Invalid API URL"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class GitHubAPIService {
    static let shared = GitHubAPIService()
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private init() {}

    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard let token = KeychainService.shared.loadPAT(), !token.isEmpty else {
            throw GitHubAPIError.noToken
        }

        var components = URLComponents(string: Constants.API.baseURL + path)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw GitHubAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.API.acceptHeader, forHTTPHeaderField: "Accept")
        request.setValue(Constants.API.apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    /// Validate the PAT by calling GET /user. Returns the authenticated username.
    func validateToken() async throws -> String {
        let request = try makeRequest(path: "/user")
        let (data, response) = try await performRequest(request)
        try checkHTTPResponse(response, data: data)
        let user = try decoder.decode(GitHubUser.self, from: data)
        return user.login
    }

    /// Fetch repo metadata to get the default branch.
    func fetchRepoInfo(owner: String, name: String) async throws -> GitHubRepo {
        let request = try makeRequest(path: "/repos/\(owner)/\(name)")
        let (data, response) = try await performRequest(request)
        try checkHTTPResponse(response, data: data)
        return try decoder.decode(GitHubRepo.self, from: data)
    }

    /// Fetch the latest workflow run for a repo's default branch.
    func fetchLatestWorkflowRun(repo: MonitoredRepo) async throws -> WorkflowRun? {
        let request = try makeRequest(
            path: "/repos/\(repo.owner)/\(repo.name)/actions/runs",
            queryItems: [
                URLQueryItem(name: "branch", value: repo.defaultBranch),
                URLQueryItem(name: "per_page", value: "1"),
            ]
        )
        let (data, response) = try await performRequest(request)
        try checkHTTPResponse(response, data: data)
        let result = try decoder.decode(WorkflowRunsResponse.self, from: data)
        return result.workflowRuns.first
    }

    /// Fetch CI status for a single repo.
    func fetchStatus(for repo: MonitoredRepo) async throws -> CIStatus {
        guard let run = try await fetchLatestWorkflowRun(repo: repo) else {
            return .unknown
        }
        return run.ciStatus
    }

    /// Fetch statuses for all repos concurrently.
    func fetchAllStatuses(repos: [MonitoredRepo]) async -> [String: CIStatus] {
        await withTaskGroup(of: (String, CIStatus).self) { group in
            for repo in repos {
                group.addTask {
                    let status = (try? await self.fetchStatus(for: repo)) ?? .unknown
                    return (repo.id, status)
                }
            }

            var results: [String: CIStatus] = [:]
            for await (id, status) in group {
                results[id] = status
            }
            return results
        }
    }

    // MARK: - Private Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw GitHubAPIError.networkError(error)
        }
    }

    private func checkHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let message: String
            if let errorResponse = try? decoder.decode(GitHubErrorResponse.self, from: data) {
                message = errorResponse.message
            } else {
                message = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            }
            throw GitHubAPIError.httpError(http.statusCode, message)
        }
    }
}
