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
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.repos) { repo in
                            RepoRowView(
                                repo: repo,
                                status: viewModel.status(for: repo),
                                onOpen: { viewModel.openInGitHub(repo) }
                            )
                            if repo.id != viewModel.repos.last?.id {
                                Divider().padding(.horizontal, 8)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
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
