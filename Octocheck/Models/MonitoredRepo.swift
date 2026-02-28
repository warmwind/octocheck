import Foundation

struct MonitoredRepo: Codable, Identifiable, Equatable {
    var id: String { "\(owner)/\(name)" }
    let owner: String
    let name: String
    var branches: [String]

    var fullName: String { "\(owner)/\(name)" }

    func statusKey(branch: String) -> String {
        "\(owner)/\(name):\(branch)"
    }

    var actionsURL: URL? {
        URL(string: "https://github.com/\(owner)/\(name)/actions")
    }

    func actionsURL(branch: String) -> URL? {
        URL(string: "https://github.com/\(owner)/\(name)/actions?query=branch%3A\(branch)")
    }

    // MARK: - Migration from old format

    enum CodingKeys: String, CodingKey {
        case owner, name, branches, defaultBranch
    }

    init(owner: String, name: String, branches: [String]) {
        self.owner = owner
        self.name = name
        self.branches = branches
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        owner = try container.decode(String.self, forKey: .owner)
        name = try container.decode(String.self, forKey: .name)

        // Try new format first, fall back to old defaultBranch
        if let branches = try? container.decode([String].self, forKey: .branches) {
            self.branches = branches
        } else if let defaultBranch = try? container.decode(String.self, forKey: .defaultBranch) {
            self.branches = [defaultBranch]
        } else {
            self.branches = ["main"]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(owner, forKey: .owner)
        try container.encode(name, forKey: .name)
        try container.encode(branches, forKey: .branches)
    }
}
