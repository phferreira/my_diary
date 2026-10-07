# Task Memory: Wire backend workflows and remove Supabase runtime

## Objective Snapshot

Route Flutter diary lookup/create/unlock, dated entry persistence, and access configuration through the backend adapter; remove the old persistence integration and display backend failures without discarding editor input.

## Important Decisions

- The application composition root selects only `BackendDiaryRepository`; missing or invalid `BACKEND_BASE_URL` uses an explicit unavailable client and an in-app message, never an in-memory store.
- Core diary metadata contains no password values or hashes. Unlock is a repository/use-case operation returning the safe `DiaryAccess` result; backend tokens remain inside the adapter.
- The in-memory repository remains a test fixture only. Password fixtures are held outside `Diary` entities.
- Backend failure text is generic at user-facing boundaries. Failed saves retain the editor document, and failed date loads restore the prior selection/content.
- Removed Supabase package, initialization/repository/password hashing code, migrations, and setup references from Flutter runtime/setup. Migration remains the separately scoped importer and reconciliation tasks.

## Learnings

- A Supabase-free scan across `README.md`, `lib`, `test`, `pubspec.yaml`, and `.github` returned no matches for Supabase or the retired hash API/config symbols.
- Deployment workflow now passes `BACKEND_BASE_URL` from the repository secret to the Flutter build.
- The checkout lacked the ignored `web/` platform scaffold even though its Pages workflow builds web; generated and force-tracked the standard scaffold, with app-specific title/description. The scaffold and `.metadata` now include the Web platform.

## Files / Surfaces

- Core entity/repository/unlock use case, app environment, and `main.dart` composition.
- Login and editor pages/view model for backend failures and retry-preserving state.
- Pubspec/lock, README, deployment workflow, removed Supabase repository/security code/migration files.
- Login, editor, backend repository, access use-case, and view-model tests.

## Errors / Corrections

- Full suite has one known baseline failure: `test/goldens/diary_editor_page.png`, 172 differing pixels from the blinking cursor; all other tests in that run passed.
- Initial full analyzer surfaced new curly-brace infos, one unused import, and one duplicate import; fixed them. Scoped analysis exits 0 and reports only existing deprecated `WidgetTester` API infos (16 in the editor test).
- The first create-failure widget test targeted the login-name field instead of the two password fields; label-based field finders corrected it, and the regression now proves the API error is visible while the dialog remains open. Added a matching access-update failure regression.

## Ready for Next Run

- Scoped validation PASS: `fvm flutter --no-version-check test test/login_page_test.dart` (8 tests), `test/update_diary_access_use_case_test.dart` (3), `test/login_view_model_test.dart` (5), `test/diary_editor_page_test.dart` (7), and `test/backend_diary_repository_test.dart` (7).
- Scoped `fvm dart analyze` across changed core/data/main/widget and focused tests exits 0; only legacy WidgetTester deprecation infos remain.
- Full `fvm flutter --no-version-check test` executes all tests except the known baseline caret golden failure (172 px).
- `fvm flutter --no-version-check build web --release --dart-define=BACKEND_BASE_URL=https://api.example.com --base-href /my_diary/` PASS (`✓ Built build/web`).
- `make gate` is unavailable because the Flutter repository has no Makefile; task-specific analyzer/tests and source/config inspections are the available evidence. Task 07 owns full browser journeys after reconciliation; tasks 04/05 own the importer and source-data reconciliation.
