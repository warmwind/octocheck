import SwiftUI

struct MenuBarPopoverView: View {
    @StateObject private var viewModel = MenuBarViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Octocheck")
                    .font(.system(size: 14, weight: .semibold))
                Text("v\(Constants.appVersion)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Updated \(viewModel.lastUpdatedText)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Error banner
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            // Repo list
            if viewModel.repos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("No repositories configured")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Open Settings to add repos")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                List(viewModel.repoBranchRows, id: \.id) { row in
                    RepoRowView(
                        repo: row.repo,
                        branch: row.branch,
                        status: viewModel.status(for: row.repo, branch: row.branch),
                        onOpen: { viewModel.openInGitHub(row.repo, branch: row.branch) }
                    )
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .frame(maxHeight: 400)
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Refresh Now") {
                    viewModel.refreshNow()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))

                Spacer()

                Button("Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
    }
}
