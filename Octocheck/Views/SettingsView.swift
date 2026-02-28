import SwiftUI

struct SettingsView: View {
    @ObservedObject private var viewModel = SettingsViewModel.shared

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            authTab
                .tabItem { Label("Authentication", systemImage: "key") }

            reposTab
                .tabItem { Label("Repositories", systemImage: "list.bullet") }
        }
        .frame(width: 480, height: 440)
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
            if let error = viewModel.repoError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            List {
                // Monitored repos
                Section("Monitored") {
                    if viewModel.repos.isEmpty {
                        Text("No repositories added yet")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(viewModel.repos) { repo in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { viewModel.expandedRepos.contains(repo.id) },
                                    set: { expanded in
                                        if expanded {
                                            viewModel.expandedRepos.insert(repo.id)
                                        } else {
                                            viewModel.expandedRepos.remove(repo.id)
                                        }
                                    }
                                )
                            ) {
                                // Workflow name
                                WorkflowNameView(
                                    workflowName: repo.workflowName,
                                    onSave: { name in
                                        viewModel.updateWorkflowName(for: repo, workflowName: name)
                                    }
                                )
                                .padding(.leading, 8)

                                // Tracked branches
                                ForEach(repo.branches, id: \.self) { branch in
                                    HStack {
                                        Image(systemName: "arrow.branch")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                        Text(branch)
                                            .font(.callout)
                                        Spacer()
                                        if repo.branches.count > 1 {
                                            Button {
                                                viewModel.removeBranch(from: repo, branch: branch)
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundStyle(.red)
                                                    .font(.caption)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }

                                // Add branch
                                BranchInputView(
                                    onAdd: { branch in
                                        viewModel.addBranch(to: repo, branch: branch)
                                    }
                                )
                                .padding(.leading, 8)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(repo.fullName)
                                            .font(.body)
                                        Text("\(repo.branches.count) branch\(repo.branches.count == 1 ? "" : "es")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        viewModel.removeRepo(repo)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Available repos to add
                Section {
                    if viewModel.isLoadingRepos {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading repositories...")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.availableRepos.isEmpty {
                        Button("Load Your Repositories") {
                            viewModel.loadAvailableRepos()
                        }
                    } else {
                        TextField("Search repos...", text: $viewModel.repoSearchText)
                            .textFieldStyle(.roundedBorder)

                        let results = viewModel.filteredAvailableRepos
                        if viewModel.repoSearchText.isEmpty {
                            Text("\(results.count) repos available — type to search")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if results.isEmpty {
                            Text("No matching repos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(results.prefix(20)) { ghRepo in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(ghRepo.fullName)
                                            .font(.body)
                                        Text(ghRepo.defaultBranch)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        viewModel.addRepo(ghRepo)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            if results.count > 20 {
                                Text("\(results.count - 20) more — refine your search")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Available")
                        Spacer()
                        if !viewModel.availableRepos.isEmpty {
                            Button {
                                viewModel.loadAvailableRepos()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .onAppear {
            if KeychainService.shared.loadPAT() != nil && viewModel.availableRepos.isEmpty {
                viewModel.loadAvailableRepos()
            }
        }
    }
}

// MARK: - Branch Picker

private struct BranchInputView: View {
    let onAdd: (String) -> Void

    @State private var branchName = ""

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .foregroundStyle(.green)
                .font(.caption)
            TextField("Branch name...", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .onSubmit {
                    addBranch()
                }
            Button("Add") {
                addBranch()
            }
            .disabled(branchName.trimmingCharacters(in: .whitespaces).isEmpty)
            .font(.callout)
        }
    }

    private func addBranch() {
        let name = branchName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        onAdd(name)
        branchName = ""
    }
}

// MARK: - Workflow Name Editor

private struct WorkflowNameView: View {
    let workflowName: String
    let onSave: (String) -> Void

    @State private var editedName: String = ""

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gearshape")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text("Workflow:")
                .font(.callout)
            TextField("CI", text: $editedName)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .frame(maxWidth: 150)
                .onSubmit {
                    onSave(editedName)
                }
        }
        .onAppear {
            editedName = workflowName
        }
    }
}
