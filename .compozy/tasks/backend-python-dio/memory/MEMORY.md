# Workflow Memory: Dedicated Python Backend for My Diary

## Shared Decisions

- The Python backend is maintained as a separate local Git repository at `../../node/my_diary_bk`; configure its remote before publishing.
- The backend owns PostgreSQL state, password verification, and short-lived scoped access tokens. Flutter receives safe diary metadata and opaque tokens only.

## Shared Learnings

- Run backend checks in the available Docker Python image when host Python lacks pip; use a disposable PostgreSQL container for persistence and transaction tests.

## Open Risks

- The backend repository currently has no remote, so its local commit is not published.
- Existing Supabase records still require an operator export and reconciliation before Supabase can be retired (task 05).

## Open Questions

