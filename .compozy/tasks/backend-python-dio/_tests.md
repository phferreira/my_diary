# Test Specification: Dedicated diary backend

Canonical test contract for the backend migration. Derived from `_user_stories.md`, `_spec.md` Part II, `_dx.md`, and `_uiux.md`.

## Strategy

- Flutter uses `package:test`/Flutter test and a fake `DiaryApiClient` at the network boundary; do not fake core logic.
- Python backend uses the repository's standard unit test runner and a disposable PostgreSQL integration database for constraints, transactions, and importer tests.
- API end-to-end journeys use the documented `/api/v1` payloads and run against the real Python HTTP app plus PostgreSQL.
- Existing Flutter UI tests remain the visual/regression harness. Baseline has a known flaky caret golden failure (172 pixels) and local FVM cache is read-only; neither should be misreported as a feature regression or passing check.

## Coverage Matrix

| Source | Behavior | Unit | Integration | E2E |
|---|---|---|---|---|
| US-001 and EC-1/EC-2 | Exact name lookup, validation, unique create | UT-001, UT-002 | IT-001 | E2E-001 |
| US-002 and EC-1/EC-2 | Password verification, safe response, token scope/permission | UT-003, UT-004 | IT-002 | E2E-001, E2E-002 |
| US-003 and EC-1/EC-2 | Date-only read, idempotent upsert, failed save feedback | UT-005, UT-006 | IT-003 | E2E-001 |
| US-004 and EC-1/EC-2 | Access transition and master-only mutation | UT-007, UT-008 | IT-004 | E2E-002 |
| US-005 and EC-1/EC-2 | Config/network/error mapping and no fallback | UT-009, UT-010 | IT-005 | E2E-003 |
| US-006 and EC-1/EC-2 | Import identity/content/date/access preservation, diagnostics, idempotency, legacy rehash | UT-011, UT-012 | IT-006 | E2E-004 |

## Unit Tests

### Flutter Dio client and repository (Part II: Core Interfaces / API Endpoints)

- **UT-001** (happy): `BackendDiaryRepository.findByName(' Leituras ')` sends `POST /api/v1/diaries/lookup` with trimmed name and maps safe diary fields without expecting password fields.
- **UT-002** (error): duplicate create response `409 diary_name_conflict` becomes a domain/data failure; it does not produce a diary or success navigation result.
- **UT-009** (error): missing/malformed `BACKEND_BASE_URL` yields a deterministic configuration failure and does not construct an in-memory/Supabase fallback repository.
- **UT-010** (error): Dio timeout and API error envelope map to typed backend failures; a failed `PUT` is not surfaced as successful save.

### Python authentication, policy, and validation (Part II: Data Models / API Endpoints)

- **UT-003** (happy): valid master password unlock produces a write token and safe diary metadata without hashes.
- **UT-004** (error): incorrect password returns generic `401 invalid_password`; unknown diary and wrong password do not reveal password-match state.
- **UT-007** (boundary): enabling public access with no public password fails when existing rules require one; an unchanged existing public password is retained when omitted.
- **UT-008** (error): public password equal to the master password is rejected and does not change persisted access state.
- **UT-011** (happy): importing SHA-256 digest preserves it as legacy verifier material; successful correct verification replaces it with Argon2id and wrong password does not rewrite it.
- **UT-012** (error): importer validates malformed row fields and emits row-numbered diagnostics without including passwords/hashes in output.

### PostgreSQL repositories (Part II: Data Models / Safety Invariants)

- **UT-005** (happy): date mapper converts `2026-10-07` to a date-only domain value without timezone shifting.
- **UT-006** (idempotency): upserting identical diary/date twice leaves one row with the latest submitted content.

## Integration Tests

### Python service and PostgreSQL

- **IT-001**: create diary, lookup by exact trimmed name, and attempt duplicate creation; expect one diary and deterministic conflict response.
- **IT-002**: unlock a migrated legacy SHA-256 protected diary; expect successful scoped write token, rehashed Argon2id column, and no password material in response.
- **IT-003**: read absent entry, save date A twice, then save/read date B; expect one row per date and independent contents.
- **IT-004**: obtain public read token, read entry, attempt save and access patch; expect reads to succeed and both writes to return 403 with persisted data unchanged.
- **IT-005**: run app with invalid token and with database unavailable; expect 401 on protected route and readiness failure without secret leakage.
- **IT-006**: dry-run then apply JSON fixture with multiple diaries/entries and legacy hashes; expect source row counts and preserved IDs/content/date/access. Reapply same fixture and expect no duplicates. Add one invalid source row and expect nonzero result, exact row diagnostic, and all-or-nothing transactional behavior.

## End-to-End Tests

### Diary journeys

- **E2E-001** (US-001, US-002, US-003): create a protected diary, find it, unlock with its master password, load a date, save content, reload, and observe the saved content.
- **E2E-002** (US-002, US-004): configure a public password, unlock through public access, read an entry, and verify editor controls are read-only and server rejects a write.
- **E2E-003** (US-005): run without `BACKEND_BASE_URL`, then against an unavailable API; observe configuration/connection failure, no fallback, no false save success, and retained editor text.
- **E2E-004** (US-006): run operator dry-run/apply against a source fixture containing diary, dated entry, and SHA-256 password; verify import summary, authenticate with original password, and verify content/identity remain intact.

## Coverage Decisions

- Existing unit coverage in `test/diary_entry_use_cases_test.dart`, `test/find_diary_use_case_test.dart`, `test/update_diary_access_use_case_test.dart`, and `test/login_view_model_test.dart` remains applicable to core behavior; it does not replace API authorization or migration coverage above.
- Every user story and edge case has a unit, integration, or end-to-end owner in the matrix. No new visual redesign is specified; existing responsive widget tests plus E2E-003 own changed feedback behavior.
