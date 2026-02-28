import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            authTab
                .tabItem { Label("Authentication", systemImage: "key") }

            reposTab
                .tabItem { Label("Repositories", systemImage: "list.bullet") }
        }
        .frame(width: 480, height: 360)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("Polling") {
                HStack {
                    Text("Interval:")
                    Picker("", selection: $viewModel.pollingInterval) {
                        Text("1 min").tag(60.0)
                        Text("2 min").tag(120.0)
                        Text("5 min").tag(300.0)
                        Text("10 min").tag(600.0)
                        Text("15 min").tag(900.0)
                        Text("30 min").tag(1800.0)
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.pollingInterval) { _ in
                        viewModel.savePollingInterval()
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)
                    .onChange(of: viewModel.launchAtLogin) { _ in
                        viewModel.toggleLaunchAtLogin()
                    }
            }

            Section("Notifications") {
                Toggle("Notify on status changes", isOn: $viewModel.notificationsEnabled)
                    .onChange(of: viewModel.notificationsEnabled) { _ in
                        viewModel.toggleNotifications()
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Auth Tab

    private var authTab: some View {
        Form {
            Section("GitHub Personal Access Token") {
                if let user = viewModel.validatedUser {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Authenticated as \(user)")
                        Spacer()
                        Button("Remove") {
                            viewModel.removeToken()
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter a GitHub PAT with `repo` scope:")
                            .font(.callout)
                        SecureField("ghp_...", text: $viewModel.token)
                            .textFieldStyle(.roundedBorder)

                        if let error = viewModel.tokenError {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }

                        Button(viewModel.isValidating ? "Validating..." : "Save & Validate") {
                            viewModel.saveAndValidateToken()
                        }
                        .disabled(viewModel.token.isEmpty || viewModel.isValidating)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Repos Tab

    private var reposTab: some View {
        VStack(spacing: 0) {
            // Add repo
            HStack {
                TextField("owner/repo", text: $viewModel.newRepoInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { viewModel.addRepo() }

                Button(viewModel.isAddingRepo ? "Adding..." : "Add") {
                    viewModel.addRepo()
                }
                .disabled(viewModel.newRepoInput.isEmpty || viewModel.isAddingRepo)
            }
            .padding()

            if let error = viewModel.repoError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            // Repo list
            List {
                ForEach(viewModel.repos) { repo in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(repo.fullName)
                                .font(.body)
                            Text("Branch: \(repo.defaultBranch)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            viewModel.removeRepo(repo)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete(perform: viewModel.removeRepos)
            }
        }
    }
}
