# Privacy Policy

Cursor Usage Menubar is a local macOS utility. This document describes what data the app accesses and transmits.

## Data read locally

The app reads from your Mac only:

| Source | Data |
|--------|------|
| `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` | `cursorAuth/accessToken`, `cursorAuth/cachedEmail` |
| `~/.cursor/projects/**/agent-transcripts/*.jsonl` | File modification times only (to trigger refresh) |

The access token never leaves your machine except when sent to Cursor's own APIs (below). The app stores a short SHA-256 fingerprint in memory to detect account switches — not the full token on disk.

## Data transmitted

The app makes HTTPS requests to:

- `https://cursor.com/api/usage-summary` (session cookie derived from your token)
- `https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage` (Bearer token fallback)

No other servers receive your data. There is no analytics SDK, crash reporter, or telemetry.

## Data not collected

- No account creation
- No cloud sync of usage data
- No logging of prompts or agent transcripts

## Your control

- Quit the app anytime from the popover
- Uninstall removes the LaunchAgent and app bundle (see README)
- Disable launch at login in Settings

## Contact

Open a GitHub issue in this repository for privacy questions.
