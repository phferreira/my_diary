# Workflow Memory: Dedicated Python Backend for My Diary

## Shared Decisions

- The Python backend is maintained as a separate local Git repository at `../../node/my_diary_bk`; configure its remote before publishing.
- The backend owns PostgreSQL state, password verification, and short-lived scoped access tokens. Flutter receives safe diary metadata and opaque tokens only.
- The importer uses a dedicated stable `LEGACY_IMPORT_FINGERPRINT_KEY`, separate from the API token signing key, to preserve rerun idempotency after legacy credential upgrades.

## Shared Learnings

- Run backend checks in the available Docker Python image when host Python lacks pip; use a disposable PostgreSQL container for persistence and transaction tests.

## Open Risks

- The backend repository currently has no remote, so its local commit is not published.
- Production diary records still require an authorized, consistent operator export and reconciliation before source retirement; only synthetic fixture data is available (task 05).

## Open Questions
