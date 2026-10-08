---
status: completed
title: Wire backend workflows and remove Supabase runtime
type: feature
complexity: high
---

# Task 3: Wire backend workflows and remove Supabase runtime

## Overview

Connect the existing diary experience to the backend repository, including remote unlock and visible operation failures that preserve unsaved editor text. Remove Supabase from Flutter runtime and setup so the configured API is the only production persistence path.

## Shippable Outcome

- Outcome: Website lookup/create/unlock, dated entry editing, and access configuration flow through the injected backend adapter; no Supabase initialization, package, configuration, migration, setup requirement, or fallback remains in Flutter.
- Verify in this task: focused Flutter domain/widget/regression checks and repository search/build configuration inspection prove the app wires the backend and handles failure without false success or lost text.
- Integration verification: task_07 owns the full browser journeys after data reconciliation.

## Requirements

- Follow `_spec.md` Impact Analysis, `_uiux.md`, and `_dx.md`; preserve current workflows and product rules.
- Replace local hash/password comparison with backend unlock and a core `DiaryAccess` result. Do not expose password material or place network logic in UI.
- Missing/invalid `API_BASE_URL` and API failures are visible; never silently use in-memory or Supabase persistence. Failed save keeps editor content available for retry.
- Supabase retirement as a production store is gated on task_05 reconciliation; this task removes client artifacts while keeping migration evidence and source data available until that gate passes.

## Subtasks

- [ ] 3.1 Update core access result/use case and login flow to rely on backend unlock outcomes.
- [ ] 3.2 Wire app composition from `API_BASE_URL`; render configuration, connection, and operation failures while preserving input.
- [ ] 3.3 Remove Supabase Flutter dependency, initialization/configuration, migration artifacts, and setup documentation/references; remove obsolete password-hash code only if unused.
- [ ] 3.4 Run focused Flutter checks and inspect source/config for unintended remaining Supabase runtime requirements.

## Implementation Details

### Relevant Files

- `lib/main.dart`, `lib/core/config/app_environment.dart` — composition/configuration.
- `lib/core/entities/diary.dart`, `lib/core/repositories/diary_repository.dart`, `lib/ui/view_models/login_view_model.dart` — safe metadata and unlock integration.
- `lib/ui/pages/diary_editor_page.dart` — access configuration feedback and save-state behavior.
- `pubspec.yaml`, `pubspec.lock`, `supabase/`, `README.md` — Supabase removal and setup replacement.
- `_uiux.md`, `_spec.md` Impact Analysis — changed surfaces and expected behavior.

### Related ADRs

- [ADR-001: Backend-enforced diary access and token sessions](adr-001-backend-access-tokens.md)

## Deliverables

- App composition using backend data adapter and required public URL configuration.
- Core/UI path using server-verified access and meaningful failure outcomes.
- Supabase-free Flutter runtime and setup.

## Tests

- Existing core and view-model coverage listed in `_tests.md` Coverage Decisions remains relevant; preserve/adapt it for server unlock semantics.
- This task owns focused checks for missing configuration, no fallback selection, failure feedback, and retained unsaved editor text. Final real-user journeys belong to task_07.

## Success Criteria

The Flutter app starts with backend configuration only, all diary operations use the new repository, local hash comparison is gone, and Supabase credentials/SDK are not required at build or runtime.
