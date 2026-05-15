# AGENTS.md

## Scope
These instructions apply to `lib/core/` and all of its descendants.

## Core responsibility
- Treat this folder as the domain and shared core layer.
- Keep business rules, entities, value objects, and use cases here.
- Expose abstractions that the UI and data layers can depend on.

## Logic checks
- Verify that the rules encoded here are framework-agnostic and reusable.
- When changing a use case or entity, confirm the behavior matches the domain rule it represents.
- Prefer explicit domain language over UI-oriented or persistence-oriented naming.

## Boundaries
- Do not introduce Flutter widget code or platform-specific dependencies here.
- Do not couple core logic to repository implementations or external integrations.
- Keep validation and invariants close to the entity or use case that owns them.

## Validation
- Add or update tests when core behavior changes.
- Prefer unit tests that exercise business rules directly.
- If a rule changes, make sure the downstream UI and data contracts still make sense.
