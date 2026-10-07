---
status: completed
title: Reconcile migrated data and retire Supabase setup
type: feature
complexity: critical
---

# Task 5: Reconcile migrated data and retire Supabase setup

## Overview

Complete the production data transition using a consistent operator-provided export and the task_04 importer. Confirm the new PostgreSQL system of record preserves records and access before treating Supabase retirement as complete.

## Shippable Outcome

- Outcome: A production snapshot is reconciled into backend PostgreSQL with source counts, identities, date/content samples, and access verification recorded; Supabase source retirement is permitted only after reconciliation passes.
- Verify in this task: operator dry-run/apply and reconciliation evidence compares counts, IDs, unique diary/date rows, and sampled authentication/access behavior; otherwise leave the source intact and record the concrete missing export/blocker.
- Integration verification: task_07 executes remaining app/API journeys against the reconciled backend where available.

## Requirements

- Requires a complete, consistent source export. No source export is included in the feature contract; acquire it through the authorized operator workflow when available. Do not fabricate or claim production reconciliation from fixtures.
- Follow `_spec.md` SD-013 and Safety Invariant 6. Do not delete/disable the old store until reconciliation confirms intended diary and entry rows.
- Complete Supabase retirement documentation/config cleanup after the data gate; no runtime dual-write or fallback is allowed in the finished app.

## Subtasks

- [ ] 5.1 Obtain and protect a consistent export; record its source counts and provenance without storing secrets in the repository.
- [ ] 5.2 Run importer dry-run, resolve any diagnostics, apply once, then reconcile counts, IDs, unique dates, representative content/access, and legacy login.
- [ ] 5.3 Once reconciliation passes, record retirement evidence and confirm Supabase is no longer required or used as runtime persistence.
- [ ] 5.4 If source export is unavailable or reconciliation fails, preserve the source and report the exact outstanding prerequisite; do not mark migration complete.

## Implementation Details

### Relevant Files

- Backend importer documented in task_04 and `/home/paulo/Documents/projects/node/my_diary_bk/`.
- `_spec.md` Impact Analysis, Development Sequencing, and Safety Invariants.
- `_dx.md` Migration Utility.

## Deliverables

- Protected source export handling and reconciliation evidence (counts, IDs, representative content/date/access checks).
- Recorded go/no-go for old-source retirement, with source preserved if evidence is incomplete.

## Tests

- Reuse the importer fixture evidence owned by task_04; do not duplicate those test contracts.
- Operator reconciliation probe: source versus destination counts/IDs and sampled diary-entry/access behavior; exact result and evidence location recorded.

## Success Criteria

Production retirement is reported only after a successful reconciliation. If external export is unavailable, the task documents that blocker and preserves the old database while other delivery work proceeds.
