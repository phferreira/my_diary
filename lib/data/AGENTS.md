# AGENTS.md

## Scope
These instructions apply to `lib/data/` and all of its descendants.

## Data responsibility
- Treat this folder as the data and integration layer.
- Keep repository implementations, data sources, mappers, and service adapters here.
- Translate external data into core-friendly models and back again.

## Logic checks
- Verify that repository behavior matches the contracts defined in core abstractions.
- When changing persistence or integration code, confirm the mapping and error handling still match the expected data flow.
- Check that data transformations preserve the information the domain needs.

## Boundaries
- Do not place business rules here if they belong in core.
- Do not expose raw external models to higher layers when a core-facing abstraction is available.
- Keep framework-specific or network-specific details isolated from the rest of the app.

## Validation
- Add or update tests when repository or integration behavior changes.
- Prefer tests that cover mapping, failure handling, and contract compliance.
- If the data contract changes, confirm the UI and core layers still consume it correctly.
