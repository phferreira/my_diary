---
status: complete
title: Python API, PostgreSQL, and access policy
type: backend
complexity: high
---

# Task 1: Python API, PostgreSQL, and access policy

## Overview

Deliver the first usable persistence path: the separate Python service can store diaries and dated entries in PostgreSQL and serve the versioned diary API. This establishes the server-owned access boundary and API that the Flutter adapter consumes.

## Shippable Outcome

- Outcome: Python API supports diary lookup/create/unlock, dated entry read/upsert, and access changes against PostgreSQL with server-enforced scoped permissions.
- Verify in this task: backend unit tests and disposable-PostgreSQL integration tests for IDs listed below; probes prove hashes never leave the server, read tokens cannot write, and date upserts remain unique.
- Integration verification: task_07 covers remaining user journeys against the real app and API.

## Requirements

- Implement in `/home/paulo/Documents/projects/node/my_diary_bk`, the separately maintained backend location.
- Follow `_spec.md` Part II, `_dx.md` HTTP/config contract, and [ADR-001](adr-001-backend-access-tokens.md). Use Python services/domain policy, PostgreSQL repositories/migrations, and HTTP handlers with stable errors.
- Preserve safe diary fields only in responses. Verify master/public passwords server-side; issue short-lived diary-scoped read/write tokens. Public-password access is read-only. Support legacy SHA-256 verification and atomic Argon2id rehash.
- Keep database/signing secrets backend-only; readiness exposes no secrets.

## Subtasks

- [x] 1.1 Establish backend configuration, app structure, PostgreSQL migrations, repositories, and health/readiness.
- [x] 1.2 Implement lookup/create/unlock services, password policies, scoped token authentication, and stable API error handling.
- [x] 1.3 Implement date-only entry access/upsert and master-only access updates transactionally.
- [x] 1.4 Exercise database constraints, authorization boundaries, safe responses, and service failure behavior.

## Implementation Details

### Relevant Files

- `/home/paulo/Documents/projects/node/my_diary_bk/` — separate Python service target.
- `_spec.md` Part II: System Architecture, Implementation Design, Safety Invariants.
- `_dx.md` — frozen public API and configuration contract.
- `_tests.md` — assigned backend test definitions.

### Related ADRs

- [ADR-001: Backend-enforced diary access and token sessions](adr-001-backend-access-tokens.md)

## Deliverables

- Python HTTP service with PostgreSQL schema/migrations and repositories.
- Versioned API, application/domain policy, scoped token handling, readiness, and safe error responses.
- Backend unit and PostgreSQL integration coverage assigned below.

## Tests

- [ ] UT-003, UT-004, UT-007, UT-008 — password verification, safe responses, and access transitions.
- [ ] UT-005, UT-006 — date-only mapping and idempotent entry upsert.
- [ ] IT-001, IT-002, IT-003, IT-004, IT-005 — CRUD, legacy unlock, date persistence, read-only enforcement, and readiness/security failures.

## Success Criteria

The API matches `_dx.md`, PostgreSQL constraints enforce the data invariants, all protected routes verify diary scope and permission server-side, and assigned tests pass in the backend repository.
