---
status: pending
title: QA plan and session charters
type: qa-report
complexity: medium
---

# Task 6: QA plan and session charters

## Overview

Select the remaining integration journeys and risk-focused checks after implementation evidence is available. Reuse task-owned contract results and plan only the real-user/API paths that remain.

## Shippable Outcome

- Outcome: QA memory and any needed scenario/charter updates identify the changed journeys, prerequisites, evidence reuse, and remaining execution scope.
- Verify in this task: inspect task evidence and QA artifacts for explicit disposition of every remaining journey and backend security/data risk.
- Integration verification: task_07 executes the selected checks.

## Requirements

- Read scope, `_spec.md`, `_dx.md`, `_uiux.md`, `_tests.md`, ADR-001, task evidence, and existing QA map; use `docs/qa` only for actual planning gaps.
- Account for public API/config and web surfaces. Map regression hotspots including token scope/expiry, public read-only restrictions, failed save retention, date-only persistence, and importer/reconciliation evidence.
- Reuse E2E-004 and unit/integration evidence already owned by tasks 01, 02, and 04; do not duplicate coverage.

## Deliverables

- Updated QA scenarios/charters only where planning gaps exist.
- Workflow QA memory recording selected walks, dependencies, and reused evidence.

## Tests

- No test ID is owned here; this task plans task_07 execution.

## Success Criteria

The selected checks cover the protected-diary, public-read-only, and service-failure journeys exactly once and name concrete app/API evidence for each.
