# Changelog

## 2.0.0

- Hero metric: API **remaining** % in menu bar (`52% | 7/16`)
- Monochrome menu bar by default; tier colors in panel only
- Settings: launch at login, compact/stacked layout, EN/ES language, optional menu bar colors
- Account switch detection via `state.vscdb` watcher
- Strict Decodable parsing + Connect RPC fallback
- Stale-data error banner; no throttle on failed fetches
- JWT base64url fix; 401 token cache invalidation
- FSEvents retry when Cursor paths are missing
- LaunchAgent without `KeepAlive` (Quit works)
- Tests for tiers, parsing, JWT
- Repo-ready: MIT, README, PRIVACY, neutral bundle ID

## 1.1.0

- Agent transcript watcher for post-agent refresh
- Menu-open polling and safety timer
- Improved error handling

## 1.0.0

- Initial menu bar app
- Reads Cursor session from local database
- Fetches usage from `cursor.com/api/usage-summary`
