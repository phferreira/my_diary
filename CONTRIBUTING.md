# Contributing

This project follows a strict workflow to keep the history readable and code
quality high. Follow the rules below for **every** change.

## Required workflow
1. Create a branch **from `develop`**.
1. Use **TDD as the priority**:
   - Write/update tests **before** implementation.
1. Implement the change.
1. **Always** run `fvm flutter analyze` and `fvm flutter test` at the end.
1. If `analyze` reports issues, **fix them and commit**.
1. If any tests fail, **fix the implementation and review the test**, then commit.
1. **Each adjustment must have its own commit** to keep history readable.
1. Open PRs **targeting `develop`** (not `main`/`master`).

## Commit conventions
- Use Conventional Commits: `type(scope): short description`.
- Prefer atomic, focused commits.
