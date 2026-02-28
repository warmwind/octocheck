import SwiftUI

struct RepoRowView: View {
    let repo: MonitoredRepo
    let branch: String
    let status: CIStatus
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: status.sfSymbol)
                .foregroundStyle(status.color)
                .font(.system(size: 14))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.fullName)
                    .font(.system(size: 13, weight: .medium))
                Text("\(branch) — \(status.label)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onOpen()
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open in GitHub")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
