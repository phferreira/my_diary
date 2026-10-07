# Dedicated Python Backend for My Diary

## Part I — Product

### Overview

- **Motivating Problem**: My Diary currently relies on Supabase from the Flutter Web client for remote diary persistence. The product needs a dedicated Python backend so the Flutter app can use a backend API while preserving the diary experience and its existing access behavior.
- **Who it is for**: People who create, find, protect, and write in diaries using the My Diary website; the project maintainer who operates its backend.
- **Why it is valuable**: Diary persistence and access decisions move behind a service boundary that the project owns, while people continue using the same core diary workflows.

### Goals

- People can find an existing diary by name or create one through the website.
- People can open diary entries by date, save entry content, and configure diary access as they do today.
- Diary and entry data remain available across browser sessions through the dedicated backend.
- The project maintainer can migrate existing diary and entry records from Supabase into the backend's PostgreSQL storage.
- The Flutter app communicates with a configurable backend service and presents clear outcomes when the service cannot complete a request.
- The website no longer requires or exposes Supabase setup to build or run.
- The backend persists diary information in PostgreSQL.

### User Stories

- Diary discovery and access: US-001–US-002.
- Dated entries and access settings: US-003–US-004.
- Backend connection and service failures: US-005.
- Migration of existing records: US-006.

[Full user stories](_user_stories.md)

### Core Features

#### Find or create a diary

People can search for a diary by its name and open it using its configured access method. If no diary exists for that name, they can create it with the existing access choices. A successful creation is immediately available through the same diary flow.

#### Read and save dated entries

People can select a date, see that date's saved entry, edit it, and save the new content. Saving one date must not replace entries from other dates.

#### Configure diary access

People can change whether a diary is public and update its master or public password using the current product rules. The interface must continue to communicate validation failures in understandable terms.

#### Connect to the dedicated service

The website uses the configured backend for diary operations. If the backend is unavailable or rejects an operation, the person receives a clear failure outcome and unsaved content is not silently reported as saved. Supabase is removed from the website's runtime and setup experience.

#### Migrate existing diary data

The project maintainer has a migration tool to transfer existing diaries and dated entries from Supabase to the dedicated backend's PostgreSQL storage. The migration preserves diary identity, content, dates, visibility, and existing password verification behavior so people can continue using their diaries after the service changes.

### Business Rules

- Diary lookup uses the full diary name as entered by the existing flow; the backend must not silently open a different diary.
- A diary has one entry per calendar date. Saving an entry for one date updates that date's content and leaves other dates intact.
- A private diary requires its master password when configured. A public diary may require its public password and remains read-only through that public access path, consistent with current behavior.
- A public password must differ from the master password. Existing password validation and access transitions remain in effect.
- A failed backend operation must not be presented as successful. Entry content that has not been confirmed saved remains visible to the person for retry during the current editing session.
- Existing diaries and entries must not be discarded as part of replacing Supabase. Their migration path must be resolved before the old storage is removed from service.
- The migration must preserve existing SHA-256 password hashes sufficiently for current diary owners to continue accessing their diaries. Successful authentication may move a legacy hash to a stronger backend-managed representation without requiring the owner to reset their password.

### User Experience

The primary journey remains: enter a diary name; open the matching diary with its password when required, or create it when it does not exist; select a date; read or edit its entry; save; and optionally adjust access settings. The dedicated service is not a separate user-facing product area. When requests fail, the website gives an understandable status and keeps the person oriented in the current diary or entry flow.

### High-Level Technical Constraints

- The Flutter Web client must call a dedicated Python backend through the Dio package.
- The backend persists diary data in PostgreSQL.
- The project removes the Supabase Flutter dependency and all Supabase-specific runtime configuration and setup.
- The service boundary must not expose password hashes to the browser as a way to authorize diary access; access checks must produce user-observable allow/deny outcomes.
- The backend is maintained separately at `../../node/my_diary_bk` relative to the Flutter repository, as requested by the project owner.
- A maintainer-facing migration capability is in scope; it must not require the Flutter application to include the Supabase SDK.

### Non-Goals (Out of Scope)

- Redesigning the diary website or changing its existing diary, entry, and access workflows beyond what is needed to use the backend.
- Adding user accounts, email login, social authentication, or a multi-user collaboration model.
- Adding new diary features unrelated to replacing the persistence service.
- Keeping Supabase as a runtime fallback or dual-writing to Supabase and the new backend.

### Open Questions

None blocking. The migration contract is an operator-provided consistent CSV/JSON export, including data extracted from a PostgreSQL dump; dry-run validation, duplicate-safe reruns, row diagnostics, and all-or-nothing apply are specified in Part II and `_dx.md`.

## Part II — Technical

### Executive Summary

Replace the Flutter Supabase repository with a Dio-backed `DiaryRepository` implementation and an injected HTTP client abstraction. The separate Python service at `../../node/my_diary_bk` owns the API, access decisions, schema, and PostgreSQL migrations. Flutter receives safe diary metadata and a short-lived bearer token after password verification; it never receives password hashes and never determines authorization by comparing hashes locally.

The backend imports legacy exports without a live Supabase integration. PostgreSQL retains current diary and per-calendar-date entry semantics. The importer is repeatable, validates and reports rejected rows, preserves valid identifiers and legacy password verification material, and enables Argon2id rehash on successful authentication. Runtime Supabase dependencies, initialization, configuration, migrations, and setup documentation are removed from Flutter.

### MVP Boundary

MVP comprises the backend schema/API, scoped access tokens, lossless export importer, Flutter Dio abstraction/repository, existing app wiring, and removal of Supabase runtime/setup. The first slice delivers find/create/unlock and one dated-entry read/write journey against PostgreSQL. Access settings and repeatable legacy import complete the MVP. Accounts, collaboration, and cloud migration orchestration are out of scope.

### Developer Experience

- [Developer experience contract](_dx.md) — Flutter build configuration, HTTP routes/payloads, errors, and operator import behavior.
- [UI change map](_uiux.md) — existing screens with backend configuration and operation failure feedback.

### System Architecture

- Flutter UI and view models continue to depend on existing core use cases.
- `DiaryRepository` remains the core-facing persistence contract. A Flutter data adapter translates it to a `DiaryApiClient`; that client owns Dio, base URL, JSON serialization, timeouts, bearer headers, and HTTP error mapping.
- Python API handlers validate requests and delegate to application/domain services. Those services perform password verification, permission checks, and transactions through repository abstractions.
- PostgreSQL is the sole runtime persistence store. The backend owns schema migrations, constraints, and connection lifecycle.
- A one-shot importer reads operator-provided export files and writes through backend validation/repository rules in an idempotent process. It is not a runtime API endpoint.

Flow: Flutter repository → injected API client/Dio → HTTPS JSON API → Python application services → PostgreSQL. Unlock returns a diary-scoped token with `read` or `write` permission. Every entry and access mutation is authorized by the backend; UI `can_edit` is only a presentation hint.

### Architectural Boundaries

- `lib/core` remains framework- and transport-independent; it must not import Dio, Flutter networking, or API DTOs.
- `lib/data` owns Dio client, request/response DTOs/mappers, and the `DiaryRepository` adapter. The composition root configures it from `BACKEND_BASE_URL`.
- UI receives core entities/use cases and does not construct HTTP requests.
- Python API handlers do not own password hashing rules or direct SQL. Domain/application services own policy; infrastructure owns PostgreSQL adapters and migrations.
- Import tooling lives in the separate Python backend, has no Supabase SDK/client dependency, and is not imported by production request handling.

### Implementation Design

#### Core Interfaces

Retain the existing core repository abstraction unchanged:

```dart
abstract class DiaryRepository {
  Future<Diary?> findByName(String query);
  Future<DiaryAccess?> unlockDiary({required Diary diary, required String password});
  Future<Diary> createDiary({required String name, required String? password,
    required bool isPublic, String? publicPassword});
  Future<DiaryEntry?> findEntryByDate({required String diaryId, required DateTime date});
  Future<void> upsertDiaryEntry({required String diaryId, required DateTime date,
    required String content});
  Future<void> updateDiaryAccess({required String id, required bool isPublic,
    String? password, String? publicPassword});
}
```

Add the framework-independent `DiaryAccess` result containing `diaryId` and `canEdit`. The repository privately retains the returned API token by diary ID; the token is not part of a core entity and is never passed to widgets. `findByName` receives a token from lookup only when passwordless access is allowed; `createDiary` retains the creator's write token. `unlockDiary` calls the backend and returns `null` for denied credentials, or `DiaryAccess` on success. Replace client-side `Diary.matchesPassword`/hash comparison with this remote use case. `Diary` carries only safe metadata (`id`, `name`, `content`, `isPublic`, `accessRequired`); neither password nor hash fields leave the backend. Public-password equality validation moves to the backend, whose deterministic `invalid_access_configuration` error is surfaced by the existing access settings flow.

New transport boundary, in the Flutter data layer:

```dart
abstract interface class DiaryApiClient {
  Future<Map<String, dynamic>> get(String path, {String? accessToken});
  Future<Map<String, dynamic>> post(String path, {
    Map<String, dynamic>? body, String? accessToken,
  });
  Future<Map<String, dynamic>> put(String path, {
    required Map<String, dynamic> body, String? accessToken,
  });
  Future<Map<String, dynamic>> patch(String path, {
    required Map<String, dynamic> body, required String accessToken,
  });
}
```

The concrete Dio client owns request options, bearer-header injection, timeouts, JSON decoding, and conversion of the API error envelope to typed data-layer failures. Repository methods map failures to explicit app outcomes; no silent memory fallback or false success. The active diary token is session-scoped and held in memory, cleared when the active diary changes or the app session ends, and never persisted to browser local storage.

#### Data Models

PostgreSQL owns normalized matchable entities:

`diaries` and `diary_entries` are relational side tables rather than JSON columns because names, date keys, foreign keys, and unique-per-day state must be matched and constrained. JSON is reserved for opaque import diagnostics/config metadata, not diary or entry state.

| Field | Type | Purpose / constraints |
|---|---|---|
| `diaries.id` | UUID primary key | Stable diary identity; preserve valid source UUID on import. |
| `diaries.name` | TEXT NOT NULL UNIQUE | Trimmed exact-name lookup and duplicate prevention. |
| `diaries.content` | TEXT NOT NULL DEFAULT `''` | Preserve legacy diary-level content. |
| `diaries.master_password_hash` | TEXT NULL | Server-only Argon2id or marked legacy SHA-256 verifier. |
| `diaries.public_password_hash` | TEXT NULL | Server-only Argon2id or marked legacy SHA-256 verifier. |
| `diaries.is_public` | BOOLEAN NOT NULL DEFAULT false | Current visibility state. |
| `diaries.created_at`, `updated_at` | TIMESTAMPTZ | Backend-maintained lifecycle timestamps. |
| `diary_entries.id` | UUID primary key | Stable entry identity; preserve valid source UUID on import. |
| `diary_entries.diary_id` | UUID NOT NULL FK → `diaries.id` ON DELETE CASCADE | Entry owner relation. |
| `diary_entries.entry_date` | DATE NOT NULL | Selected calendar date, with no timezone conversion. |
| `diary_entries.content` | TEXT NOT NULL DEFAULT `''` | Serialized editor content without rewriting. |
| `diary_entries.created_at`, `updated_at` | TIMESTAMPTZ | Backend-maintained lifecycle timestamps. |
| `UNIQUE(diary_id, entry_date)` | constraint | One entry per diary/date and idempotent upsert. |

Name uniqueness/normalization must match existing trimmed exact-match behavior. Entry dates are calendar dates with no timezone conversion. Content remains the editor's serialized text without server rewriting.

Safe API diary response is `{id, name, is_public, access_required}` and never includes either hash. Unlock response is `{access_token, can_edit}`. Token claims contain diary ID, permission (`read`/`write`), issue/expiry timestamps, and token identifier; token is signed with a backend secret. Default TTL is 15 minutes; re-unlock issues a fresh token.

Legacy password inputs may be plaintext or lowercase 64-character SHA-256. Verification uses constant-time comparison for digest comparisons. After successful legacy verification, Argon2id hash is persisted atomically. New/updated passwords are trimmed as current behavior and stored with Argon2id and documented secure parameters. Never log raw passwords, tokens, or hashes.

#### API Endpoints

The frozen request/response examples and failure envelopes are in `_dx.md`. Required routes: `POST /api/v1/diaries/lookup`, `POST /api/v1/diaries`, `POST /api/v1/diaries/{id}/unlock`, `GET` and `PUT /api/v1/diaries/{id}/entries/{date}`, and `PATCH /api/v1/diaries/{id}/access`. Validate date syntax, field lengths, and access transitions. Creation, rehash, access change, and entry upsert use transactions. Unlock failures do not distinguish nonexistent diary from incorrect password in the public error message.

Every entry and access mutation route authenticates a token scoped to the route diary ID and checks permission server-side. A write token is required to save or change access; a read token may load entries only. Invalid/expired token gives `401`, valid token without permission gives `403`, and missing diary gives `404`. No handler trusts Flutter `can_edit`.

#### Integration Points

- Flutter Web → Python API: HTTPS in production; CORS allowlist contains deployed GitHub Pages origin(s), with no wildcard credentials. Dio uses connect/receive/send timeouts. Do not automatically retry create/unlock. GET can be retried once for transient failure; entry PUT and access PATCH are idempotent and may retry only with the identical payload.
- Python API → PostgreSQL: backend-only deployment secret, TLS between hosts, bounded connection pool and transaction timeout. No database or signing secret enters Flutter build config.
- Offline import: local exported input, validate before commit, report counts/errors without printing sensitive values. No network credentials needed.

### Impact Analysis

| Component | Impact Type | Description and Risk | Required Action |
|---|---|---|---|
| Flutter repository composition | modified | API replaces current remote persistence and changes failure behavior. | Add Dio API client/repository and explicit configuration failures. |
| Flutter diary/access domain and login flow | modified | Current `Diary` carries password hashes and `LoginViewModel` checks them locally. | Replace password fields/comparisons with safe access metadata and an `unlockDiary` use case that delegates to the backend; retain tokens only inside the data adapter. Remove `PasswordHasher`/`crypto` if no other consumers remain. |
| Supabase client/config | deleted | Browser adapter currently fetches password hashes and calls tables. | Remove repository, initialization/imports, Supabase `AppEnvironment` fields, package dependency, SQL migrations and setup docs/references. Internal hard cut: no fallback, shim, or placeholder. |
| Separate Python backend | new | Owns API, data, auth policy and import. | Implement Python service, PostgreSQL migrations, importer, configuration and deployment contract. |
| Existing Supabase user state | migrated | Diaries and entries must not be discarded. | Export/import and reconcile rows, IDs and sampled access/entry behavior before disabling/deleting old store. No runtime dual-write. |
| Public HTTP API | new | Externally callable access surface. | Version `/api/v1`; short-lived scoped tokens, strict CORS, rate limits, stable error envelope. |
| Flutter build config | modified | Backend origin is public compile-time configuration. | Add `BACKEND_BASE_URL`; require absolute HTTP(S), HTTPS except local development. Remove Supabase defines and docs. |
| UI failure states | modified | Prior memory fallback could mask failed persistence. | Keep unsaved editor content and do not show success on API failure. |

SD-013: persistent diary state is migrated losslessly in the same delivery before Supabase is retired; importer verifies row counts, IDs, unique diary/date records, and sampled access behavior. The public API is new/versioned; no compatibility shim is needed. Supabase client/config are internal hard cuts in the same change with no fallback/shim/placeholder.

### Extensibility Integration Plan

No plugin, extension, hook, agent tool, MCP, or third-party runtime surface is added. Checked surfaces are Flutter composition and the HTTP API; neither has an extension registry. API versioning is the compatibility mechanism for the new service.

### Agent Manageability Plan

Operators run a deterministic importer over a local JSON/CSV export or extracted PostgreSQL dump, with dry-run and explicit apply modes. It reports total/imported/already-present/rejected counts and row-numbered diagnostics, exits nonzero on invalid data or incomplete application, and supports duplicate-safe reruns. Backend health/readiness reports service and PostgreSQL readiness without secrets. Freeze exact CLI syntax in the backend implementation contract before task execution.

### Config Lifecycle

- Flutter `BACKEND_BASE_URL`: required public compile-time origin; absolute HTTP(S), HTTPS outside localhost. Missing/invalid value produces visible startup configuration feedback and never selects in-memory/Supabase persistence.
- Backend `DATABASE_URL`: required runtime secret, never sent to client.
- Backend `TOKEN_SIGNING_KEY`: required runtime secret with rotation procedure, never committed or sent to browser.
- Backend `ALLOWED_ORIGINS`: explicit production origin list.
- Backend `LEGACY_IMPORT_FINGERPRINT_KEY`: importer-only stable secret of at least 32 characters, required for repeat imports after legacy verifier upgrades; separate from `TOKEN_SIGNING_KEY` and retained unchanged across its rotation.
- Token TTL defaults to 15 minutes. Hash parameters use documented secure defaults; only backend operator configuration may override them.

### Testing Approach

Flutter unit tests cover Dio request construction, DTO mapping, token use, error mapping, and repository contract. Backend unit tests cover lookup, access transitions, legacy password upgrade, authorization and validation. PostgreSQL integration tests cover constraints, foreign keys, transactions, upsert, and import reruns on an isolated database. API journey covers create → lookup → unlock → entry read/write → public read-only → denied write. Migration verification compares counts/IDs and tests legacy password authentication before old storage is retired.

Baseline evidence: existing Flutter full suite has one unrelated flaky editor golden failure caused by caret blinking (172 pixels; masked/isolated diff shows cursor bars). `fvm flutter --version` fails because the shared cache is read-only. This is known baseline evidence; implementation owners must report rerun status accurately.

### Development Sequencing

#### Build Order

1. Freeze API/token/error contracts, schema, and import format; gate: contract review.
2. Implement Python services, PostgreSQL adapter/migrations, importer, unit/integration tests; gate: clean DB and sample export pass.
3. Implement Flutter Dio client/repository/mappers with fake transport tests; gate: repository contract tests pass.
4. Wire composition root and UI failure states; gate: browser journey passes.
5. Export production source, dry-run/import/reconcile; gate: counts, IDs, sampled access and entry checks pass before old source retirement.
6. Delete Supabase artifacts/dependency/docs; gate: Flutter dependency resolution/analyze/tests and backend suite pass.

#### Technical Dependencies

- PostgreSQL service and deployment secrets are needed for integration/deployment.
- Backend target `/home/paulo/Documents/projects/node/my_diary_bk` must be available to the delivery workflow (user approved worktree access).
- A complete, consistent source export is required before old storage retirement. If unavailable, preserve the old database and do not claim migration complete.
- Inspect actual exported schema before importer implementation; support documented CSV/JSON and dump extraction without a runtime Supabase SDK.

### Monitoring and Observability

Log request ID, route, status, latency and safe error code; never log passwords, tokens, hashes, or entry content. Monitor request failure/latency, PostgreSQL readiness/pool exhaustion, rate-limit events, and import completion counts. Alert on sustained DB failure and elevated 5xx.

### Technical Considerations

#### Key Decisions

- PostgreSQL is the backend-owned system of record (user decision); the backend, not the Flutter client, owns schema and access policy.
- Dio remains behind a Flutter data-layer abstraction so transport details do not cross into Core and can be faked at the network boundary.
- Server verification plus short-lived diary-scoped read/write tokens replaces unsafe client hash comparison while preserving accountless user flows.
- Argon2id is used for new password storage; legacy plaintext/SHA-256 is accepted for compatibility only and upgraded on successful verification.
- Import/reconcile precedes old storage retirement; no runtime dual-write or fallback is retained.

#### Known Risks

- Stolen bearer tokens grant scoped access until expiry. Mitigate with HTTPS, 15-minute expiry, memory-only client storage, CORS allowlist and server authorization.
- Name lookup enables enumeration; rate-limit lookup and password attempts, and avoid revealing unknown-vs-wrong password on unlock.
- Legacy SHA-256 is unsalted/fast. Restrict export access, rehash on successful login, and securely delete temporary export files after reconciliation.
- GitHub Pages has no server-side secret store. Only API origin is public client configuration; signing/database secrets remain backend-only.
- Source exports can have schema drift/orphans; dry-run and row diagnostics must precede source retirement.

### Safety Invariants

1. No response, log or exception contains stored hashes, raw passwords or bearer tokens.
2. Every protected request authenticates a token scoped to the route diary and authorizes its required permission server-side.
3. A public read token cannot save entries or change access settings, regardless of client flags.
4. `(diary_id, entry_date)` remains unique; repeating a save replaces that date's value without duplicate records.
5. Import is validated, transactional, duplicate-safe and reports failures without silent partial loss.
6. Supabase storage is not retired before reconciliation confirms intended diary and entry rows.

### File References

#### Repo Files

- `lib/core/repositories/diary_repository.dart` — stable persistence interface.
- `lib/core/entities/diary.dart` and `lib/core/entities/diary_entry.dart` — domain behavior and mapping targets.
- `lib/ui/view_models/login_view_model.dart` — local unlock comparison to replace with backend authentication use case.
- `lib/ui/pages/diary_editor_page.dart` — access password validation to retain in UI where local format rules apply and delegate secret equality validation to the backend.
- `lib/data/repositories/supabase_diary_repository.dart` — CRUD/access behavior to port, then delete.
- `lib/data/repositories/in_memory_diary_repository.dart` — test-fake behavior; not production fallback.
- `lib/core/security/password_hasher.dart` — legacy SHA-256 representation to verify during migration.
- `lib/main.dart` and `lib/core/config/app_environment.dart` — composition/configuration to replace.
- `supabase/migrations/*.sql` — current schema/constraints to preserve in backend migrations, then delete.
- `README.md` — current Supabase setup/schema docs to replace.
- `_dx.md` — frozen API and configuration contract.
- `_user_stories.md` — accepted user behavior and migration intent.

### Assumptions and Defaults

- PostgreSQL is selected and owned by the Python backend.
- Production API uses HTTPS; localhost development may use HTTP.
- Tokens are opaque, diary-scoped, 15-minute credentials; Flutter stores them in memory only.
- Names retain existing trimmed exact-match behavior; entry date is date-only.
- Import source is operator-provided CSV/JSON or extracted PostgreSQL dump; importer has no Supabase SDK dependency.
- Legacy hashes remain verifiable until successful authentication upgrades them.
- `BACKEND_BASE_URL`, `DATABASE_URL`, signing key and allowed origins are deployment contracts; exact host/platform are deployment choices.
- `LEGACY_IMPORT_FINGERPRINT_KEY` is provisioned only for the offline importer and remains stable while imported snapshots may be re-applied.

### Architecture Decision Records

- [ADR-001: Backend-enforced diary access and token sessions](adr-001-backend-access-tokens.md) — move verification/authorization to Python and issue scoped short-lived tokens instead of exposing hashes to Flutter.
