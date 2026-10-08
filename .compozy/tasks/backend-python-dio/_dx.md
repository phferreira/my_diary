# Developer Experience: Dedicated diary backend

Public contract for the Flutter web client and the Python backend. Companion to `_spec.md` and `_tests.md`.

## HTTP API

Base URL is supplied to the Flutter build as `API_BASE_URL`; all routes use `/api/v1`. Requests and responses use JSON. IDs are opaque strings. Dates use ISO `YYYY-MM-DD`. The client never sends a Supabase credential.

### Lookup a diary

`POST /api/v1/diaries/lookup`

```json
{"name":"Leituras"}
```

`200 OK` for a protected diary:

```json
{"diary":{"id":"d_01JABC","name":"Leituras","is_public":false,"access_required":true}}
```

For a diary without a password requirement, lookup returns a session token so entry requests remain authenticated: `{"diary":{"id":"d_01JABC","name":"Leituras","is_public":false,"access_required":false},"access_token":"eyJ...","can_edit":true}`. This preserves the current passwordless behavior. A passwordless public diary follows the current app's edit behavior; public-password access is always read-only.

`404 Not Found`: `{"error":{"code":"diary_not_found","message":"Diary not found."}}`

Names are exact-match after trimming, matching the current application. Password hashes are never returned.

### Create a diary

`POST /api/v1/diaries`

```json
{"name":"Meu diário","password":"master-pass","is_public":false}
```

`201 Created` returns the safe diary representation and a master access token:

```json
{"diary":{"id":"d_01JABC","name":"Meu diário","is_public":false,"access_required":true},"access_token":"eyJ...","can_edit":true}
```

`password` may be null or omitted for a diary without a master password. The initial diary is private.

If the normalized exact name already exists, creation returns `409 Conflict`: `{"error":{"code":"diary_name_conflict","message":"A diary with this name already exists."}}`.

### Unlock a diary

`POST /api/v1/diaries/{diary_id}/unlock`

```json
{"password":"master-pass"}
```

`200 OK` returns `{"access_token":"eyJ...","can_edit":true}` for a master password, or `{"access_token":"eyJ...","can_edit":false}` for the public password of a public diary. `401 Unauthorized`: `{"error":{"code":"invalid_password","message":"Password is incorrect."}}`.

Tokens are bearer credentials. Use `Authorization: Bearer <access_token>` on diary entry and access-control routes. Tokens are scoped to one diary and carry read/write permission; clients treat them as opaque.

### Read and save a daily entry

`GET /api/v1/diaries/{diary_id}/entries/{date}` returns `200 OK` with `{"diary_id":"d_01JABC","date":"2026-10-07","content":""}`. A date without a saved entry returns the same shape with empty content.

`PUT /api/v1/diaries/{diary_id}/entries/{date}` with `{"content":"..."}` returns `200 OK` with the stored entry. Repeating a request replaces the same diary/date record. Both routes require a valid scoped token. A public-password token can read; only a master token can save. Failures use `403 Forbidden` and `{"error":{"code":"read_only_access","message":"This access cannot modify the diary."}}` for a write attempted with a read-only token.

### Change diary access

`PATCH /api/v1/diaries/{diary_id}/access` requires master write permission.

```json
{"is_public":true,"public_password":"reader-pass"}
```

`200 OK` returns the safe diary representation. If changing to private, `password` may be omitted to retain the current master password, empty to clear it, or non-empty to replace it. If changing to public, an existing public password is retained when `public_password` is omitted; otherwise the supplied non-empty password is set. The public password must differ from the master password. Errors use `400` with `invalid_access_configuration`, `401` for invalid/expired token, and `403` for read-only access.

## Configuration

Flutter builds set `API_BASE_URL`, for example:

```sh
fvm flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

The production value is the HTTPS origin of the deployed API. It is public client configuration, never a secret. With no URL configured, app startup reports a configuration error; it does not silently switch to in-memory persistence.

## Migration utility

An operator runs the backend's one-shot import command against a consistent exported source dataset (JSON or CSV, including files extracted from a PostgreSQL dump). It imports diary metadata and daily entries into PostgreSQL, preserves IDs where valid, and is safe to rerun without creating duplicate diaries or entries. A dry run validates all rows without mutation; apply reports total, imported, already-present, rejected, and row-level diagnostics. Apply is all-or-nothing: any invalid or conflicting row aborts the transaction, exits nonzero, and reports affected source rows. Reapplying an already imported identical snapshot succeeds and imports zero duplicates. Existing password values may be plaintext or SHA-256 hashes; imports retain them only in the legacy-compatible verifier, then successful authentication upgrades them to Argon2id. The importer accepts exported data files and does not connect to Supabase.

The canonical JSON input has `diaries` and `diary_entries` arrays. Diary rows contain `id`, `name`, `content`, `password`, `public_password`, and `is_public`; entry rows contain `id`, `diary_id`, `entry_date`, and `content`. CSV input uses one file for each table with those same headers. Valid UUIDs and all source fields are preserved. Plaintext source passwords are Argon2id-hashed during import; SHA-256 values are retained as marked legacy verifiers until successful login upgrades them. An existing ID/name/date with conflicting data is rejected, never overwritten silently.

## Errors

All errors use `{"error":{"code":"...","message":"..."}}`. `400` means invalid request/date/access configuration; `401` means invalid or expired credentials; `403` means a valid token lacks permission; `404` means the diary or route resource does not exist; `409 diary_name_conflict` means a duplicate diary name; `422` means a field fails validation; `429` means the password attempt limit was reached; `500` means an unexpected server failure. Messages do not disclose stored hashes, password values, or whether a password hash matched.
