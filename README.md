# Cursor Usage Menubar

Native macOS menu bar app that shows **Cursor API usage** at a glance — especially how much of your **named-model API quota is used** (GPT, Claude, Opus) without opening Cursor Settings.

## Features

- **Menu bar format:** `48% | 7/16` — API **used** % | Cursor tier used (Agent, Composer, Grok, Auto) / Total used
- **Monochrome menu bar** (v2) — color tiers in the popover panel only
- **Tooltip** on hover explains each metric
- **Auto-refresh** when Cursor agents finish (watches `~/.cursor/projects/.../agent-transcripts/`)
- **Account switch detection** — refreshes when Cursor auth changes
- **Settings:** launch at login, compact/stacked layout, EN/ES language, optional menu bar colors
- **Privacy-first:** reads your local Cursor session token only; no third-party servers

## Screenshots

> Placeholder — add screenshots before publishing the repo.

## Requirements

- macOS 13+
- [Cursor](https://cursor.com) signed in (reads `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`)
- Swift 5.9+ (Xcode 15+ or Swift toolchain)

## Install

```bash
git clone <your-repo-url>
cd cursor-usage
./scripts/install.sh
```

This builds a release binary, installs:

- **App:** `~/Applications/Cursor Usage Menubar.app`
- **CLI:** `~/.local/bin/cursor-usage-menubar`

Open at Login is **on by default** (System Settings > General > Login Items). Turn it off in the app **Settings** panel.

Agents and step-by-step install, verify, and uninstall: see [AGENTS.md](AGENTS.md).

### Manual launch

```bash
open ~/Applications/Cursor\ Usage\ Menubar.app
```

## Refresh behavior

| Trigger | Interval |
|---------|----------|
| App startup | immediate |
| Menu open | every 90s while open |
| Agent transcript change | ~2s debounce |
| Background safety poll | every 5 min |

## API disclaimer

This app calls Cursor's authenticated usage endpoints (`cursor.com/api/usage-summary`, with a Connect RPC fallback that runs only when the primary fails). Field-level details are in [AGENTS.md](AGENTS.md). It is **unofficial** and not affiliated with Cursor. API shape may change; report issues if parsing breaks.

## Privacy

See [PRIVACY.md](PRIVACY.md). Summary:

- Reads `cursorAuth/accessToken` and `cursorAuth/cachedEmail` from your local Cursor database
- Sends the session token only to `cursor.com` / `api2.cursor.sh` to fetch your usage
- No analytics, no cloud storage, no account creation

## Uninstall

```bash
# First turn off "Launch at login" in the app Settings
pkill -x CursorUsageMenubar 2>/dev/null || true
rm -rf ~/Applications/Cursor\ Usage\ Menubar.app
rm -f ~/.local/bin/cursor-usage-menubar
```

## Development

```bash
swift build
swift test
swift run
```

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Mac App Store

Not supported — the app needs filesystem access to Cursor's local database and is incompatible with App Store sandboxing.

## License

MIT — see [LICENSE](LICENSE).

## Español

Ver [README.es.md](README.es.md).
