# QA Report: Remaining backend migration journeys

## Scope Selected

- E2E-001: Flutter web diary create/find/master unlock, date-only entry save/reload, duplicate-date invariant, and incorrect-password behavior against the Python API/PostgreSQL.
- E2E-002: owner enables distinct public password; fresh public session reads but cannot edit; direct API write is denied and persisted content is unchanged.
- E2E-003: missing configuration and unavailable API render visible failures; forms remain retryable; failed save retains text and reports no success; recovery permits retry.
- E2E-004 is owned by task 04 and its synthetic PostgreSQL CLI journey is reused.

## Reused Evidence

- Task 01 backend unit/API/PostgreSQL tests cover password policy, token scope, authorization and date persistence.
- Task 02/03 Flutter unit/widget tests and web build cover Dio mapping, login/editor failure feedback, retry retention, and access settings.
- Task 04's 28-test backend run includes importer CLI and PostgreSQL integration evidence, with synthetic fixture identity/content/date/access preservation, reruns, rollback, redaction, and credential upgrade.
- The known full Flutter suite golden failure is the baseline blinking cursor (172 pixels), recorded in task 03 memory; it is not used as a passing result.

## Planning Gap Addressed

No `docs/qa` scenarios or charters existed. Added `docs/qa/backend-python-dio-journeys.md` with concrete setup, actions, pass criteria, evidence reuse, and teardown expectations for task 07. It keeps production parity separate from synthetic importer verification.

## Prerequisites and Boundaries

- Task 07 needs a disposable local PostgreSQL instance, local API, Flutter web build, and a browser or browser automation. Confirm available browser tooling before execution. Do not claim widget tests as browser journeys.
- Task 05's production reconciliation remains unverified until an authorized consistent operator export is available. No production data or live source is to be used for the local journeys.
- The worktree has no Makefile, so `make gate-status`/`make gate` are unavailable; existing focused task evidence is reused without claiming a gate run.

## Ready for Next Run

- Task 07 owns execution and dated results for E2E-001, E2E-002, and E2E-003, including environment details and cleanup. E2E-004 is reused unless importer source/schema/environment changes.
- Production export reconciliation remains an external prerequisite to any production migration or source retirement claim.
