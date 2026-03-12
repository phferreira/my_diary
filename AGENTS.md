# AGENTS.md

## Scope
These instructions apply to the entire repository.

## Project goal
This project is a personal website built with **Flutter Web** (Dart), published on GitHub Pages.

## Development standard (Flutter)
- Use **idiomatic Dart** and prioritize readability over overly complex solutions.
- Prefer small, reusable widgets; avoid putting too much logic directly inside `build`.
- Keep consistency with `analysis_options.yaml` and run `fvm dart format` on changed files (use `dart format` if `fvm` is not installed).
- For relevant visual changes, validate locally on web (`fvm flutter run -d chrome`, or `flutter run -d chrome` if `fvm` is not installed) and include evidence when possible.
- Consider the existing **Design System** when developing or updating widgets, keeping visual and behavioral consistency across the app.
- Before adding text directly in widgets, check and prefer string constants in `lib/core/constants/app_strings.dart`.

## Architecture standard
- Follow **Clean Architecture** principles for all new features.
- Keep clear separation of concerns between layers:
  - **Presentation/UI**: widgets, page state, and user interaction.
  - **Domain/Core**: business rules, entities, and use cases.
  - **Data**: repositories, data sources, and external integrations.
- Ensure dependencies point inward (UI -> Domain/Core <- Data abstractions).
- Avoid placing business rules directly in widgets or framework-specific code.

## Current project structure (must be followed in new features)
- Use the existing structure as the default for new work:
  - `lib/core/`: shared domain/core logic and cross-cutting concerns.
  - `lib/data/`: data/repository implementations and integrations.
  - `lib/ui/`: presentation layer (pages/widgets/view logic).
  - `test/`: unit and widget tests.
- New features should be added under these folders, preserving the same layering and naming patterns already used in the project.

## Feature workflow
For new features:
1. implement UI/behavior in the appropriate layer;
2. add/update tests in `test/`;
3. run `fvm flutter test` before finishing (or `flutter test` if `fvm` is not installed).

## Quality checklist
Before completing changes, try to run:

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test

If `fvm` is not installed, replace the commands above with `flutter ...`.
```

If any command cannot be run due to environment limitations, document it in the final summary.

## Version control standard
- Use **Conventional Commits** as the default for all commit messages.
- Follow the format: `type(scope): short description`.
- Prefer clear types such as `feat`, `fix`, `docs`, `refactor`, `test`, and `chore`.
- Prefer atomic/unitary commits per specific change to keep diffs clear and focused.
