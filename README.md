# Octocheck

A lightweight macOS menu bar app that monitors GitHub Actions CI status across your repositories at a glance.

<img width="24" alt="menu bar icon" src="https://developer.apple.com/sf-symbols/"> <!-- placeholder -->

## What It Does

Octocheck sits in your menu bar and continuously polls GitHub Actions for the latest workflow status on your selected repositories. The menu bar icon reflects the aggregate state — green when everything passes, red if anything fails, orange while builds are running.

Click the icon to see a breakdown of each repo, open any repo's Actions page in your browser, or trigger a manual refresh.

## Features

- **Aggregate status icon** — one look tells you if all CI is green
- **Per-repo breakdown** — see individual status, branch, and last update time
- **Configurable polling** — 1, 2, 5, 10, 15, or 30-minute intervals (default 5 min)
- **Secure auth** — GitHub PAT stored in macOS Keychain, never written to disk
- **Desktop notifications** — get notified when a repo's status changes (e.g. passing → failing)
- **Network-aware** — pauses polling when offline, resumes automatically
- **Launch at Login** — optional auto-start via macOS ServiceManagement
- **No Dock icon** — runs purely as a menu bar utility

## Requirements

- macOS 13 (Ventura) or later
- A GitHub Personal Access Token with `repo` scope (or `public_repo` for public repos only)

## Getting Started

### Build & Run

```bash
git clone https://github.com/yourname/Octocheck.git
cd Octocheck
chmod +x build-app.sh
./build-app.sh
open Octocheck.app
```

This builds via Swift Package Manager and wraps the binary in a proper `.app` bundle.

### Setup

1. Click the Octocheck icon in your menu bar → **Settings**
2. Go to the **Authentication** tab and enter your GitHub PAT
3. Go to the **Repositories** tab and add repos in `owner/repo` format (e.g. `apple/swift`)
4. The default branch is detected automatically — statuses start polling immediately

## Usage

### Menu Bar

Once running, Octocheck lives in your menu bar. Click the icon to open the popover:

- Each row shows a repo's name, current CI status, and a colored indicator
- Click the **arrow icon** on any row to open that repo's GitHub Actions page in your browser
- Click **Refresh Now** to fetch statuses immediately instead of waiting for the next poll
- Click **Quit** to exit the app

### Managing Repositories

- Open **Settings → Repositories**
- Type a repo in `owner/repo` format (e.g. `facebook/react`) and click **Add**
- Octocheck auto-detects the default branch and starts monitoring
- Click the **trash icon** next to a repo to remove it

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
| `questionmark.circle` | **Unknown** | No workflow runs found or repo not configured |

**Aggregate logic:** any failure → red; else any running → orange; else all success → green.

## API Usage

Octocheck calls `GET /repos/{owner}/{repo}/actions/runs?branch={branch}&per_page=1` per repo. With 10 repos at a 5-minute interval, that's ~120 requests/hour — well within GitHub's 5,000 req/hr limit.

## License

MIT
