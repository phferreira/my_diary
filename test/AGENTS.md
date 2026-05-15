# AGENTS.md

## Scope
These instructions apply to `test/` and all of its descendants.

## Test responsibility
- Treat this folder as the place for unit, widget, and integration-style validation for the app.
- Keep tests focused on observable behavior, not implementation details.
- Organize tests so they clearly match the layer or feature they validate.

## Logic checks
- Verify that the expected behavior is covered before assuming a change is correct.
- When a core, data, or UI rule changes, confirm the relevant test still expresses the intended contract.
- Prefer tests that fail for the right reason when behavior regresses.

## Boundaries
- Do not encode production logic in tests.
- Avoid brittle assertions that depend on incidental formatting or private implementation details.
- Keep fixtures and helpers reusable when they support multiple related test cases.

## Validation
- Update or add tests whenever behavior changes.
- Prefer direct assertions over indirect checks when they better describe the expected result.
- Run the relevant test command for the affected scope, and keep failures visible until they are understood.
