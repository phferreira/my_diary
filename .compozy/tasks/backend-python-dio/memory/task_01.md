# Task Memory: Python API, PostgreSQL, and access policy

## Objective Snapshot

Deliver the backend persistence/API foundation with server-owned password checks, scoped read/write tokens, date-only entries, and safe responses.

## Important Decisions

- The backend is its own Git repository at `/home/paulo/Documents/projects/node/my_diary_bk`; there is no remote configured yet. Its task checkpoint is commit `d8b8efc00ee9e5290f5b3ae669045a3b9040fa70`.
- PostgreSQL is accessed through psycopg and SQL is isolated in `DiaryRepository`; application password/access policy is in `app/services.py`; Argon2id and HMAC token handling are in `app/security.py`.
- Public-password unlocks yield read-only tokens; passwordless lookup yields a write token only when neither master nor public password is configured.
- Signing secret is backend-only and startup/readiness reject missing or weak configuration.

## Learnings

- The host Python lacks pip and needed modules. Tests ran in the available `python:3.11-alpine` Docker image against a disposable PostgreSQL container.
- The Flutter worktree has no `Makefile`, so `make gate` is unavailable; no Flutter files were changed in this backend-only checkpoint.

## Files / Surfaces

- Backend API, repository, domain services, security, SQL migration, Docker/Compose configuration, requirements, README, and API/security/policy tests in `/home/paulo/Documents/projects/node/my_diary_bk`.
- Feature task graph and workflow evidence in `.compozy/tasks/backend-python-dio/`.

## Errors / Corrections

- Initial test assertion expected a boolean but password verification deliberately returns `(valid, verifier)`; corrected the test to assert the boolean component.
- Initial task review caught protected public-diary lookup metadata/token behavior and equality checking against an existing master verifier; fixed both and added regression coverage.
- `TestClient` required `httpx2` with current Starlette; kept it in the optional test dependency set, not production requirements.

## Ready for Next Run

- Scoped validation PASS: `python -m compileall -q app tests` and `python -m unittest discover -s tests -v` in a disposable Python 3.11 container with PostgreSQL; 13 tests passed, including create/duplicate, legacy rehash, scoped token, public read-only, date upsert, readiness failure, and password policy.
- `git diff --check` passed before backend checkpoint commit.
- `cy-final-verify` assessment: PASS for task 01's API/persistence/access contract. Remaining integrated Flutter/API journeys and visual acceptance belong to task 07; importer coverage belongs to task 04; Supabase retirement/reconciliation belongs to task 05.
