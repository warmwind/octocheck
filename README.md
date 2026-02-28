# Octocheck

A lightweight macOS menu bar app that monitors GitHub Actions CI status across your repositories at a glance.

## What It Does

Octocheck sits in your menu bar and continuously polls GitHub Actions for the latest workflow status on your selected repositories. The menu bar icon reflects the aggregate state — orange while any build is running, red if anything fails, green when everything passes.

Click the icon to see a breakdown of each repo and branch, open any repo's Actions page in your browser, or trigger a manual refresh.

## Features

- **Colored status icon** — green/red/orange/gray menu bar icon at a glance
- **Multi-branch tracking** — monitor multiple branches per repository
- **Per-repo workflow name** — configure which workflow to track per repo (default: "CI")
- **Aggregate status icon** — one look tells you if all CI is green
- **Per-repo breakdown** — see individual status, branch, and last update time
- **Configurable polling** — 1, 2, 5, 10, 15, or 30-minute intervals (default 5 min)
- **Secure auth** — GitHub PAT stored locally with restricted file permissions
- **Desktop notifications** — get notified when a repo's status changes (e.g. passing → failing)
- **Network-aware** — pauses polling when offline, resumes automatically
- **Launch at Login** — optional auto-start via macOS ServiceManagement
- **No Dock icon** — runs purely as a menu bar utility

## Requirements

- macOS 13 (Ventura) or later
- A GitHub Personal Access Token with `repo` scope (or `public_repo` for public repos only)

## Getting Started

### Quick Start (Pre-built)

A pre-built `Octocheck.app` is included in the repo. Just clone and run:

```bash
git clone https://github.com/warmwind/octocheck.git
cd octocheck
open Octocheck.app
```

> **Note:** macOS may show a security prompt since the app is unsigned. Go to **System Settings → Privacy & Security** and click **Open Anyway**.

### Build from Source

If you prefer to build it yourself:

```bash
git clone https://github.com/warmwind/octocheck.git
cd octocheck
chmod +x build-app.sh
./build-app.sh
open Octocheck.app
```

This builds via Swift Package Manager and wraps the binary in a proper `.app` bundle.

### Setup

1. Click the Octocheck icon in your menu bar → **Settings**
2. Go to the **Authentication** tab and enter your GitHub PAT
3. Go to the **Repositories** tab, load your repos, and add the ones you want to monitor
4. Expand a repo to add branches and configure the workflow name to track
5. Statuses start polling immediately

## Usage

### Menu Bar

Once running, Octocheck lives in your menu bar. Click the icon to open the popover:

- Each row shows a repo's name, branch, current CI status, and a colored indicator
- Click the **arrow icon** on any row to open that repo's GitHub Actions page in your browser
- Click **Refresh Now** to fetch statuses immediately instead of waiting for the next poll
- Click **Quit** to exit the app

### Managing Repositories

- Open **Settings → Repositories**
- Click **Load Your Repositories** to fetch your GitHub repos
- Click the **+** icon to add a repo (its default branch is added automatically)
- Expand a repo to add more branches or change the tracked workflow name
- Click the **-** icon to remove a repo or branch

### Changing Settings

Open **Settings → General** to:

- **Polling interval** — how often Octocheck checks GitHub (1 min to 30 min)
- **Launch at Login** — start Octocheck automatically when you log in
- **Notifications** — toggle desktop notifications for status changes (e.g. a build breaks or recovers)

### Creating a GitHub PAT

1. Go to [GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Select the `repo` scope (for private repos) or `public_repo` (for public repos only)
4. Copy the token and paste it into **Settings → Authentication** in Octocheck

## Status Indicators

| Icon | State | Meaning |
|------|-------|---------|
| `checkmark.circle` | **Passing** | Latest workflow run succeeded |
| `xmark.circle` | **Failing** | Latest workflow run failed or timed out |
| `arrow.triangle.2.circlepath` | **Running** | Workflow is in progress, queued, or pending |
| `questionmark.circle` | **Unknown** | No matching workflow runs found |

**Aggregate logic:** any running → orange; else any failure → red; else all success → green.

## API Usage

Octocheck calls `GET /repos/{owner}/{repo}/actions/runs?branch={branch}&per_page=20` per repo×branch, filtered by the configured workflow name. With 10 repo×branch combinations at a 5-minute interval, that's ~120 requests/hour — well within GitHub's 5,000 req/hr limit.

## License

MIT
