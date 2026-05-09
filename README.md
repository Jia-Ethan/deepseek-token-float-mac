# DeepSeek Token Float Mac

Native macOS desktop monitor for checking DeepSeek API balance and viewing locally recorded DeepSeek token usage.

This is a native macOS app, not an Electron app, web dashboard, or CLI-only script. DeepSeek is the only enabled provider in the current phase; Kimi, OpenAI, and Claude are reserved in the provider model for later integration.

## Current Features

- Native macOS floating monitor panel built with SwiftUI and AppKit `NSPanel`.
- Menu bar control for showing/hiding the widget, opening Settings, refreshing balance, and quitting.
- Desktop-grade dark glass monitor UI with dense account and usage metrics.
- Time span selector: Today, Week, Month, 30D, and All.
- Account balance, local monthly spend, API request count, total tokens, model usage, and daily token trend.
- Double-click opens Settings.
- Official DeepSeek balance lookup via `GET https://api.deepseek.com/user/balance`.
- Settings window for pasting, saving, testing, and clearing the DeepSeek API Key.
- Manual language switch in Settings: English and Simplified Chinese.
- Provider status section with DeepSeek enabled and future providers marked as planned.
- API Key is stored in macOS Keychain, not in the repository.
- Local SQLite usage database.
- Manual CSV import for local usage records.
- Empty state when no local usage records exist.

## Data Source

Balance data is official. The app calls:

```http
GET https://api.deepseek.com/user/balance
Authorization: Bearer <DEEPSEEK_API_KEY>
```

Token usage is local-only in this phase. DeepSeek public API docs expose token counts in individual API responses, but do not expose a public historical usage aggregation API for Today, Week, Month, 30D, or All.

That means the monitor currently shows token usage, model usage, request count, daily trend, and monthly spend only for records imported or captured locally. It does not claim to represent official full-account historical usage.

Estimated cost is shown only when imported records include cost/amount data. Otherwise it is displayed as unavailable.

## Requirements

- macOS 14 or later.
- Swift toolchain.
- A DeepSeek API Key for balance lookup.

This repository is Swift Package based, so it can be built with the Swift command line toolchain.

## Run Locally

```bash
swift run DeepSeekTokenFloatMac
```

The app launches as an accessory-style floating monitor panel. Use the gear button to open Settings.

## Build a Local `.app`

```bash
./scripts/package_app.sh
open "dist/DeepSeek Token Float.app"
```

The packaged app is a local unsigned menu bar utility at `dist/DeepSeek Token Float.app`.

## Import Local Usage

Open Settings, then choose **Import Usage CSV**.

Required columns:

- `timestamp`
- `input_tokens` or `prompt_tokens`
- `output_tokens` or `completion_tokens`

Optional columns:

- `id`
- `provider`
- `model`
- `total_tokens`
- `estimated_cost`
- `source`

See [docs/usage-import-format.md](docs/usage-import-format.md).

## Security Notes

- Never commit API keys.
- API keys are saved through macOS Keychain using a generic password item.
- API keys are not printed to logs by the app.
- Local usage data is stored under the user's Application Support directory.
- `.gitignore` excludes local databases, logs, environment files, build outputs, and common secret file types.

## Known Limitations

- No official historical token usage API is integrated because one was not found in DeepSeek public API docs.
- Usage statistics are not full-account truth unless the imported data is complete.
- CSV import is intentionally simple and local-first.
- No signed `.app` bundle or notarized release yet.
- No automatic interception of external DeepSeek API calls yet.

## Roadmap

- Add import support for DeepSeek platform Usage export ZIP/CSV once the exact exported schema is verified.
- Add optional local proxy/capture mode for apps that choose to route DeepSeek requests through this monitor.
- Add signed `.app` bundle and release workflow.
- Add model-aware estimated cost rules with explicit cache hit/miss handling.
- Add launch-at-login option.
- Consider other providers after the DeepSeek-only MVP is stable.

## License

MIT
