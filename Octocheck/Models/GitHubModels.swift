import Foundation

struct WorkflowRunsResponse: Decodable {
    let totalCount: Int
    let workflowRuns: [WorkflowRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }
}

struct WorkflowRun: Decodable {
    let id: Int
    let workflowId: Int
    let name: String?
    let status: String     // queued, in_progress, completed, etc.
    let conclusion: String? // success, failure, cancelled, skipped, etc.
    let htmlURL: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case workflowId = "workflow_id"
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var ciStatus: CIStatus {
        switch status {
        case "completed":
            switch conclusion {
            case "success":
                return .success
            case "failure", "timed_out":
                return .failure
            default:
                return .unknown
            }
        case "in_progress", "queued", "waiting", "pending", "requested":
            return .running
        default:
            return .unknown
        }
    }
}

struct GitHubUser: Decodable {
    let login: String
    let id: Int
}

struct GitHubRepo: Decodable, Identifiable {
    var id: String { fullName }
    let fullName: String
    let defaultBranch: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case defaultBranch = "default_branch"
    }
}

struct GitHubBranch: Decodable, Identifiable {
    var id: String { name }
    let name: String
}

struct GitHubErrorResponse: Decodable {
    let message: String
}
