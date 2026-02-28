import Foundation

struct MonitoredRepo: Codable, Identifiable, Equatable {
    var id: String { "\(owner)/\(name)" }
    let owner: String
    let name: String
    let defaultBranch: String

    var fullName: String { "\(owner)/\(name)" }

    var actionsURL: URL? {
        URL(string: "https://github.com/\(owner)/\(name)/actions")
    }
}
