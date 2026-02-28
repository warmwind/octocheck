import Foundation

/// Stores the GitHub PAT in a file under Application Support with 600 permissions.
/// This avoids Keychain prompts that occur with unsigned/ad-hoc signed builds.
final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(Constants.appName, isDirectory: true)
        return dir.appendingPathComponent(".token")
    }

    func savePAT(_ token: String) throws {
        let dir = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data = Data(token.utf8)
        try data.write(to: storageURL, options: [.atomic, .completeFileProtection])

        // Restrict file permissions to owner read/write only (0600)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: storageURL.path
        )
    }

    func loadPAT() -> String? {
        guard let data = try? Data(contentsOf: storageURL),
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty
        else { return nil }
        return token
    }

    func deletePAT() throws {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        try FileManager.default.removeItem(at: storageURL)
    }
}
