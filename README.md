# DeepSeek Token Float Mac

Apple-style macOS floating widget for checking DeepSeek API balance and viewing locally recorded DeepSeek token usage.

This is an early MVP. It is a native macOS app, not an Electron app, web dashboard, or CLI-only script.

## Current Features

- Native macOS floating card built with SwiftUI and AppKit `NSPanel`.
- Light Apple-style card: rounded glass surface, subtle shadow, clear information hierarchy.
- Time span selector: Today, Week, 30D, and All.
- Official DeepSeek balance lookup via `GET https://api.deepseek.com/user/balance`.
- Settings window for saving, testing, and clearing the DeepSeek API Key.
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

Token usage is local-only in this MVP. As of the initial research pass, DeepSeek public API docs expose token counts in individual API responses and document a platform Usage page with monthly CSV export, but do not expose a public historical usage aggregation API for Today, Week, 30D, or All.

That means the widget currently shows token usage only for records imported or captured locally. It does not claim to represent official full-account historical usage.

Estimated cost is shown only when imported records include cost/amount data. Otherwise it is displayed as unavailable.

## Requirements

- macOS 14 or later.
- Swift toolchain.
- A DeepSeek API Key for balance lookup.

This repository is currently Swift Package based because the local development machine only has Command Line Tools available, not a full Xcode.app installation.

## Run Locally

```bash
swift run DeepSeekTokenFloatMac
```

The app launches as an accessory-style floating panel. Use the gear button to open Settings.

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
- No menu bar status item yet.
- No automatic interception of external DeepSeek API calls yet.

## Roadmap

- Add import support for DeepSeek platform Usage export ZIP/CSV once the exact exported schema is verified.
- Add optional local proxy/capture mode for apps that choose to route DeepSeek requests through this monitor.
- Add signed `.app` bundle and release workflow.
- Add model-aware estimated cost rules with explicit cache hit/miss handling.
- Add menu bar affordance and launch-at-login option.
- Consider other providers after the DeepSeek-only MVP is stable.

## License

MIT
