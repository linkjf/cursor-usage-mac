# Contributing

Thanks for helping improve Cursor Usage Menubar.

## Setup

```bash
git clone <repo>
cd cursor-usage
swift build
swift test
```

## Pull requests

1. Keep changes focused — one concern per PR when possible
2. Run `swift build -c release` and `swift test` before submitting
3. Match existing Swift style (2-space indent in this project)
4. Update `CHANGELOG.md` for user-visible changes
5. Do not commit secrets or personal bundle IDs

## Reporting bugs

Use the bug report template and include:

- macOS version
- Cursor version
- Menu bar label shown vs expected
- Relevant error text from the popover

## Architecture notes

- `UsageModel` — refresh orchestration, watchers, menu bar state
- `LiveUsageFetcher` — SQLite token read + HTTP to Cursor APIs
- `UsageMenuView` — popover UI + settings
- `L10n` — EN/ES strings with system locale default
