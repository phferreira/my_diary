---
status: pending
title: Flutter Dio client and repository adapter
type: frontend
complexity: high
---

# Task 2: Flutter Dio client and repository adapter

## Overview

Add a transport boundary in Flutter's data layer so repository behavior can use the new API without leaking Dio or wire DTOs into core or UI. This gives later app wiring a tested adapter and deterministic configuration/error failures.

## Shippable Outcome

- Outcome: Flutter has an injectable `DiaryApiClient` backed by Dio and a `DiaryRepository` implementation that maps safe API data, keeps access tokens in memory, and maps failed requests into explicit failures.
- Verify in this task: fake-client unit tests cover request paths/payloads, mapping, configuration, timeout/error mapping, and unsuccessful save outcomes.
- Integration verification: task_07 covers complete browser/API journeys.

## Requirements

- Implement in Flutter `lib/data/`; keep `lib/core` transport-independent. Follow `_spec.md` Core Interfaces and `_dx.md`.
- Use the Dio package, `BACKEND_BASE_URL`, configured timeouts, JSON mapping, and bearer headers. Do not add Supabase or memory fallback behavior.
- Keep returned tokens private to the adapter, in memory only; clear them when active diary/session changes. Never put tokens in core entities, widgets, logs, or persistent browser storage.

## Subtasks

- [ ] 2.1 Define transport abstraction and concrete Dio implementation with base URL validation, timeouts, serialization, and error conversion.
- [ ] 2.2 Map API DTOs to core entities and implement `DiaryRepository`, including token retention and unlock outcomes.
- [ ] 2.3 Verify repository request/mapping/error behavior using fake transport at the network boundary.

## Implementation Details

### Relevant Files

- `lib/data/` — client, DTOs, mappers, and repository adapter.
- `lib/core/repositories/diary_repository.dart` and `lib/core/entities/diary.dart` — stable domain contract and safe mapping targets.
- `_spec.md` Part II: Core Interfaces and Architectural Boundaries.
- `_dx.md` — route, payload, errors, and `BACKEND_BASE_URL` contract.

### Related ADRs

- [ADR-001: Backend-enforced diary access and token sessions](adr-001-backend-access-tokens.md)

## Deliverables

- Injectable `DiaryApiClient` and Dio implementation.
- Backend-backed repository mapping safe fields and typed failures.
- Unit coverage for all assigned contracts.

## Tests

- [ ] UT-001, UT-002 — trimmed lookup mapping and duplicate creation conflict.
- [ ] UT-009, UT-010 — invalid configuration, timeout/error conversion, and failed-save behavior.

## Success Criteria

No Dio/API types cross into core or UI; fake-client tests prove the public route contract and every assigned failure has a non-success result.
