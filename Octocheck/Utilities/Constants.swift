import Foundation

enum Constants {
    static let appName = "Octocheck"
    static let bundleID = "com.octocheck.app"

    enum API {
        static let baseURL = "https://api.github.com"
        static let acceptHeader = "application/vnd.github+json"
        static let apiVersion = "2022-11-28"
    }

    enum Keychain {
        static let service = bundleID
        static let account = "github-pat"
    }

    enum UserDefaultsKeys {
        static let monitoredRepos = "monitoredRepos"
        static let pollingInterval = "pollingInterval"
        static let launchAtLogin = "launchAtLogin"
        static let notificationsEnabled = "notificationsEnabled"
    }

    enum Defaults {
        static let pollingInterval: TimeInterval = 300 // 5 minutes
        static let minPollingInterval: TimeInterval = 60
        static let maxPollingInterval: TimeInterval = 1800
    }
}
