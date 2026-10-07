# Task Memory: Build the repeatable legacy data importer

## Objective Snapshot

Provide a backend-owned offline importer for canonical JSON or paired CSV exports, preserving diary and entry identifiers, access configuration, content, and dates while supporting safe dry runs and all-or-nothing idempotent applies.

## Important Decisions

- Import runs separately from API request handling. Its documented CLI accepts `--json` or paired `--diaries-csv` and `--entries-csv`, with exactly one of `--dry-run` and `--apply`.
- Passwords supplied in plaintext are immediately Argon2id hashed. SHA-256 values are retained only as marked legacy verifiers and upgraded after a successful login.
- A dedicated stable `LEGACY_IMPORT_FINGERPRINT_KEY` HMACs imported credential provenance so rerunning a legacy snapshot stays idempotent after login rehash without retaining the weak source verifier. This key is independent of `TOKEN_SIGNING_KEY`; credential changes clear the corresponding provenance.
- Apply preflights the full snapshot under a transaction and writes no partial data on conflicts. Dry run uses a read-only transaction. Safe diagnostics identify source rows and fields without rendering credential values.
- The backend runtime configuration follows the feature contract names `TOKEN_SIGNING_KEY` and `ALLOWED_ORIGINS`.

## Learnings

- Use a user-defined Docker network for disposable PostgreSQL integration tests when the test container cannot resolve the host gateway. Remove both the DB container and test network after evidence is collected.
- The fixture covers both SHA-256 and plaintext credential imports, a password-protected public diary, and dated entries. PostgreSQL assertions verify preserved data and credential behavior.

## Files / Surfaces

- Backend importer parser, validation, CLI, transactional repository operations, migration schema, and credential provenance.
- Backend README and `docs/legacy-import.md` operating contract.
- Unit tests, CLI journey tests, PostgreSQL integration tests, and synthetic JSON fixture.
- Feature spec config lifecycle, assumptions, and importer summary contract.

## Errors / Corrections

- The first PostgreSQL test network could not reach the host gateway; moved the disposable DB and Python test runner onto a user-defined Docker network.
- The API regression test for explicit password update initially missed the fingerprint invalidation import; fixed and reran the complete suite.
- Spec preflight initially found stale importer summary field names; aligned the spec with `total/imported/already_present/rejected` and reran marker preflight successfully.

## Ready for Next Run

- Backend validation PASS: disposable Docker Python/PostgreSQL run `python -m compileall -q app tests && python -m unittest discover -s tests -v` completed **28 tests, OK**. Coverage includes JSON and CSV dry-run/apply, reruns, conflict and malformed-row diagnostics, secret redaction, atomic rollback, preserved IDs/content/dates/access, SHA-256 verification and post-login rehash idempotence, plaintext Argon2id idempotence, and provenance invalidation after password changes.
- `git diff --check` PASS. `_spec.md` marker preflight PASS: `check-spec-markers.py` reported all required quality markers.
- Removed disposable `diary-import-tests` PostgreSQL container and `diary-import-net` after verification. The Python test container used `--rm`.
- Task 05 owns production export reconciliation and requires an operator-provided export; source retirement remains gated on reconciliation. Task 07 owns full browser journey verification.
- Flutter repository `make gate` is unavailable because no Makefile/gate target exists; task 03 records the focused Flutter tests, analyzer, and web build evidence.
