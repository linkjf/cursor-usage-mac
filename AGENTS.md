# AGENTS.md

Instructions for AI agents installing, running, or changing **Cursor Usage Menubar** (native macOS menu bar app for Cursor API usage).

## Requirements

- macOS 13+ (`Package.swift`: `.macOS(.v13)`)
- Swift 5.9+ (Xcode 15+ or Swift toolchain)
- Cursor installed and signed in (app reads `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`)

## Install

Run from the repo root:

```bash
./scripts/install.sh
```

The script:

1. Runs `swift build -c release`
2. Stops a running `CursorUsageMenubar` process
3. Installs the CLI to `~/.local/bin/cursor-usage-menubar`
4. Installs the app bundle to `~/Applications/Cursor Usage Menubar.app` (writes `Info.plist`, `LSUIElement`, `LSMinimumSystemVersion` 13.0)
5. Deletes LaunchAgent plists `com.cursorusage.menubar` and `com.linkjf.cursor-usage-menubar` (login is not a LaunchAgent anymore)
6. Opens the app. On its first launch from the bundle it registers **Open at Login** via `SMAppService`, on by default

Do not create a LaunchAgent plist for login. Login is a Login Item.

## Verify

```bash
pgrep -x CursorUsageMenubar
```

- The menu bar shows `NN% | a/b`: API **used** % | Cursor tier used / Total used
- Settings > "Launch at login" is on
- If the Settings panel shows "Approve in System Settings", the user must enable it in System Settings > General > Login Items

## Run manually

```bash
open "$HOME/Applications/Cursor Usage Menubar.app"
```

The app is single-instance (`SingleInstanceGuard`). A second launch activates the running instance and exits.

## Build and test

```bash
swift build
swift test
swift build -c release
```

## Uninstall

1. Turn off "Launch at login" in the app Settings, or in System Settings > General > Login Items
2. Quit the app and remove the bundle and CLI:

```bash
pkill -x CursorUsageMenubar 2>/dev/null || true
rm -rf "$HOME/Applications/Cursor Usage Menubar.app"
rm -f "$HOME/.local/bin/cursor-usage-menubar"
```

## Code map

- `Sources/CursorUsageMenubar/AppDelegate.swift`: launch order, single-instance check, first-run login setup
- `LaunchAtLoginManager.swift`: `SMAppService` login item and legacy LaunchAgent cleanup
- `StatusBarController.swift`, `MenuBarStatusItemView.swift`: AppKit `NSStatusItem` and menu bar rendering
- `UsageMenuView.swift`: SwiftUI popover and settings
- `UsageModel.swift`, `UsageSnapshot.swift`, `UsageFetcher.swift`: refresh, metrics, Cursor API and local SQLite token
- `L10n.swift`: EN and ES strings. Add new keys to both tables

## Conventions

- 2-space indent for Swift (see `CONTRIBUTING.md`)
- Menu bar and panel show API **used** %. Tier colors use **remaining** %
- Update `CHANGELOG.md` for user-visible changes
- Do not commit secrets or personal bundle IDs
