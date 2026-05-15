# AGENTS.md

## Scope
These instructions apply to `lib/ui/` and all of its descendants.

## UI responsibility
- Treat this folder as the presentation layer: widgets, pages, view models, and interaction wiring belong here.
- Keep UI code focused on rendering, user interaction, and state presentation.
- Do not place business rules or domain decisions in widgets when they can live in core or data abstractions.

## UI logic checks
- Verify that widget conditions, callbacks, and state transitions match the expected user flow.
- When changing a screen or component, confirm the UI still reacts correctly to the underlying view model or state source.
- If a UI branch looks suspicious, inspect the surrounding state changes before assuming the widget is correct.

## Visual consistency
- Consider the existing **Design System** when developing or updating widgets.
- Keep visual and behavioral consistency across the app.
- Before adding text directly in widgets, check and prefer string constants in `lib/core/constants/app_strings.dart`.

## Validation
- For relevant visual changes, validate locally on web with `fvm flutter run -d chrome` or `flutter run -d chrome` if `fvm` is not installed.
- Prefer tests when UI behavior can be verified with widget coverage.
- Include evidence when possible for changes that affect layout, interaction, or rendering.
