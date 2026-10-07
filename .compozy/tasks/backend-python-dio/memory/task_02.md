# Task Memory: Flutter Dio client and repository adapter

## Objective Snapshot

Provide an injectable HTTP boundary and a core-facing repository that maps safe backend data, keeps opaque bearer tokens in memory, and reports network/API failure without false success.

## Important Decisions

- `DiaryApiClient` is the transport abstraction; `DioDiaryApiClient` owns URL validation, JSON, timeouts, bearer headers, and conversion into `BackendFailure`.
- `BackendDiaryRepository` retains only one active diary token in memory and exposes `clearSession()`; token data is absent from core entities and widgets.
- Core `DiaryAccess` carries diary ID and the UI-facing edit hint; `Diary.accessRequired` represents server-safe protection metadata without hashes.
- Existing Supabase and in-memory repositories temporarily implement the new unlock signature to keep the app compiling; task 03 will remove Supabase and wire backend outcomes into login.

## Learnings

- Dio 5.11.1 resolves from the `^5.9.2` constraint. The existing pub cache allowed package resolution without relying on the read-only FVM SDK cache.
- The app-wide analyzer has existing deprecation/performance infos; targeted analysis of new client/repository/entity surfaces is clean.

## Files / Surfaces

- `lib/data/clients/diary_api_client.dart` and `dio_diary_api_client.dart`.
- `lib/data/repositories/backend_diary_repository.dart`; core access entity/repository contract; temporary implementations in memory and Supabase adapters.
- `pubspec.yaml`, `AppEnvironment`, and `test/backend_diary_repository_test.dart`.

## Errors / Corrections

- First red test run failed because Dio and the new client/API types did not yet exist, as expected.
- Full Flutter suite retains the known `diary_editor_page.png` caret diff (172 pixels); all other executed test groups passed. This is the baseline failure documented in `_tests.md`.
- Fixed a new curly-brace analyzer info in the date mapper; targeted analysis then reported no issues.

## Ready for Next Run

- Scoped validation PASS: `fvm flutter test test/backend_diary_repository_test.dart` (7 tests) and `fvm dart analyze lib/data/clients lib/data/repositories/backend_diary_repository.dart lib/core/entities/diary_access.dart` (no issues).
- Full `fvm flutter test`: known single caret golden failure (172 px); the run completed other tests successfully.
- App-level Supabase removal, composition wiring, and login/access outcomes remain task 03; full browser/API journeys and visual verification remain task 07.
