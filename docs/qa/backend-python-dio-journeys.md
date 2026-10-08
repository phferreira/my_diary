# Backend migration journey QA charter

This charter owns the remaining real app/API journeys for task 07. Run against a disposable local PostgreSQL database and the Python API. Do not use or mutate production data. Use synthetic diary names and passwords, and do not put credentials or exported user data in reports.

## Reused evidence

- Task 01 backend suite covers API validation, scoped tokens, public read-only policy, and PostgreSQL persistence.
- Task 02 and task 03 Flutter suites cover request mapping, error mapping, editor save retention, login failure feedback, and access UI behavior. The web release build also passed.
- Task 04 importer suite covers JSON/CSV dry-run/apply, diagnostics/redaction, transaction rollback, identity/content/date/access preservation, reruns, and legacy password upgrade. This evidence uses a synthetic fixture and does not prove production data reconciliation.
- The full Flutter suite has one known baseline golden discrepancy from a blinking cursor (172 pixels); preserve this as existing environmental/flaky evidence and inspect any other new failure independently.

## E2E-001 — Protected diary create, unlock, and dated save

1. Start an isolated PostgreSQL database and the API with a valid signing key and the Flutter web app with `API_BASE_URL` pointed at that API.
2. In a fresh browser context, create a diary with a unique name and master password. Confirm the app enters the diary only after the API confirms creation.
3. Reload, find the diary by exact name, unlock with its master password, open a date, enter unique content, and save.
4. Reload the date and confirm the content persists. Query the disposable database to confirm one diary and one row for the selected diary/date; do not expose password verifiers in captured output.
5. Try an incorrect password and confirm generic invalid-password feedback without entering the diary.

Pass: create/find/unlock/save/reload all succeed; repeated save for the same diary/date leaves one row; wrong password never authenticates.

## E2E-002 — Public password grants read only

1. Use a fresh diary and persist a dated entry through an owner session.
2. Enable public access with a distinct public password. Open a fresh browser context and unlock through public access.
3. Confirm the entry is visible and editor/save controls are read only. Attempt a write directly against the API with the public token.
4. Confirm the API returns forbidden and the persisted entry remains unchanged. Confirm public password cannot equal the master password using the app validation path.

Pass: public read succeeds, app prevents editing, backend rejects direct write, and database state is unchanged.

## E2E-003 — Missing/unavailable backend and retained editor text

1. Open the app without `API_BASE_URL`; confirm an in-app configuration message renders and no local fallback diary is created.
2. Configure a deliberately unavailable local API and attempt lookup/create; confirm a visible service failure and a retryable form.
3. In an authenticated disposable diary, enter unsaved editor text, make the API unavailable, and trigger a save. Confirm a visible failure, no success indication, and text remains available for retry.
4. Restore the API and retry; confirm the text persists only after the server confirms the write.

Pass: configuration/network failures render without crashing startup, there is no fallback persistence, failed save does not discard content or claim success, and retry succeeds after recovery.

## E2E-004 — Import journey

Reuse task 04's completed PostgreSQL CLI journey; do not rerun unless importer source, schema, or environment changes. Its fixture is synthetic and is not production reconciliation.

## Explicit prerequisite and exclusions

- Production reconciliation remains blocked until an authorized, consistent operator export is provided. Do not run apply against an unknown source, retire the production source, or report production parity from fixture data.
- Browser automation availability must be checked before task 07. If no browser automation is installed, use a real browser manually if available and record the exact execution mode; do not count widget tests as browser journeys.
- Task 07 must record actual outcomes, environment/version details, API/database readiness, and teardown. Remove all disposable databases and test artifacts after each run.
