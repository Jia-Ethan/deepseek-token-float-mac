# Usage CSV Import Format

The app does not claim official full-account token history unless DeepSeek exposes a formal historical usage API in the future.

For the current MVP, token usage comes from local records imported into SQLite.

## Required columns

- `timestamp`: ISO-8601 date/time, Unix seconds, or `yyyy-MM-dd`.
- `input_tokens`: input token count. `prompt_tokens` is also accepted.
- `output_tokens`: output token count. `completion_tokens` is also accepted.

## Optional columns

- `id`: stable record id. A UUID is generated when omitted.
- `provider`: defaults to `deepseek`.
- `model`: defaults to `unknown`.
- `total_tokens`: defaults to `input_tokens + output_tokens`.
- `estimated_cost`: decimal amount, usually USD unless your source says otherwise.
- `source`: defaults to `manual_csv_import`.

## Example

```csv
timestamp,provider,model,input_tokens,output_tokens,total_tokens,estimated_cost,source
2026-05-05T10:12:00Z,deepseek,deepseek-v4-flash,1200,360,1560,0.000269,manual_csv_import
```
