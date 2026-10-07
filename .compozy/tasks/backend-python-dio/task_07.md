---
status: completed
title: Real-user and API journey QA
type: qa-execution
complexity: high
---

# Task 7: Real-user and API journey QA

## Overview

Run the selected app and API journeys after task-specific tests and data reconciliation are complete. Verify the website's visible behavior agrees with backend authorization and persisted state.

## Shippable Outcome

- Outcome: Remaining end-to-end user journeys pass against the real Python HTTP app and PostgreSQL, or defects/blockers are recorded with reproducible evidence.
- Verify in this task: execute the browser/API walks selected by task_06; verify persisted data and denied writes where relevant. Reuse the operator import journey evidence from task_04.
- Integration verification: none; this is the final QA execution owner.

## Requirements

- Follow task_06 plan, existing QA scenarios, and `cy-loop-tasks` QA evidence conventions. Use browser automation for web flows and real API/database state for authorization and persistence assertions.
- Include configuration missing/unavailable service behavior, unsaved text retention, protected diary unlock/save/reload, public read-only experience, and server-side denied write.
- Record actual evidence and environment limitations; do not claim runs that were blocked by missing backend deployment, PostgreSQL, or production export.

## Deliverables

- Updated scenario verdicts and dated QA report for actual execution.
- Defects registered and linked to affected scenarios, if found.
- Explicit evidence disposition for all selected journeys.

## Tests

- [ ] E2E-001 — create, find, unlock, read, save, and reload a dated entry.
- [ ] E2E-002 — public password read-only journey and rejected server write.
- [ ] E2E-003 — missing configuration/unavailable API, no fallback, no false save success, retained text.

## Success Criteria

All selected journeys have a passing result or a concrete, reproducible blocker/defect record; previously owned E2E-004 evidence is referenced rather than rerun without cause.
