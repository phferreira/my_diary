---
status: completed
title: Build the repeatable legacy data importer
type: backend
complexity: high
---

# Task 4: Build the repeatable legacy data importer

## Overview

Give the maintainer a backend-owned, offline tool to validate and import a consistent exported snapshot into PostgreSQL. The importer preserves identities and access behavior while making bad or conflicting source rows visible before any source retirement.

## Shippable Outcome

- Outcome: Operator can dry-run and apply JSON/CSV exports without a Supabase SDK; valid repeated snapshots are idempotent, invalid/conflicting apply is all-or-nothing, and legacy credentials remain verifiable.
- Verify in this task: importer unit tests plus PostgreSQL integration and CLI journey checks cover row diagnostics, transactional rollback, preserved content/IDs/date/access, idempotency, and SHA-256 compatibility.
- Integration verification: task_07 covers app journeys; task_05 owns production source reconciliation before retirement.

## Requirements

- Implement under `/home/paulo/Documents/projects/node/my_diary_bk`, separate from Flutter request handling. Freeze exact CLI syntax in the backend implementation contract before implementation.
- Follow `_dx.md` Migration Utility and `_spec.md` Safety Invariants. Accept canonical JSON or paired CSV exports; preserve valid IDs and source fields; hash plaintext with Argon2id and preserve SHA-256 as marked legacy verification data.
- Dry-run has no mutation. Apply is transactional, duplicate-safe, rejects conflicts instead of overwriting, exits nonzero on invalid/incomplete input, and diagnostics never print secrets.

## Subtasks

- [ ] 4.1 Specify importer CLI/input schema and row-level validation behavior in backend documentation.
- [ ] 4.2 Implement dry-run and transactional apply using backend validation/repository rules.
- [ ] 4.3 Verify reruns, preserved records, diagnostics, secret redaction, legacy verification, and rollback using fixture data and PostgreSQL.

## Implementation Details

### Relevant Files

- `/home/paulo/Documents/projects/node/my_diary_bk/` — importer and backend persistence implementation.
- `_dx.md` Migration Utility — accepted input/output behavior.
- `_spec.md` Importer design, sequencing, and safety invariants.
- `_tests.md` — assigned importer coverage.

### Related ADRs

- [ADR-001: Backend-enforced diary access and token sessions](adr-001-backend-access-tokens.md)

## Deliverables

- Documented offline importer command and JSON/CSV contract.
- Dry-run/apply path with transactional and idempotent semantics.
- Unit, PostgreSQL integration, and CLI journey evidence.

## Tests

- [ ] UT-011, UT-012 — legacy hash upgrade behavior and malformed-row diagnostics with secret redaction.
- [ ] IT-006 — dry-run/apply, preserved IDs/content/dates/access, idempotency, and all-or-nothing invalid-row handling.
- [ ] E2E-004 — operator dry-run/apply journey with migrated password authentication and preserved entry.

## Success Criteria

Fixture import matches source counts and required data exactly; repeat apply creates no duplicates; invalid apply leaves PostgreSQL unchanged and reports row-specific safe diagnostics.
