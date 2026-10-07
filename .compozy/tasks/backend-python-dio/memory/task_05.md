# Task Memory: Reconcile migrated data and retire legacy persistence

## Objective Snapshot

Reconcile the real production export through the task 04 importer and only authorize source retirement after counts, identities, content/date samples, and access behavior match.

## Important Decisions

- Production reconciliation cannot be inferred from the synthetic importer fixture. No external production snapshot or authorized export endpoint is available in the workspace.
- Keep the production source intact and do not claim migration or retirement. Task 05 explicitly assigns this fallback to subtask 5.4 and requires documenting the missing export.
- The importer is ready for a consistent operator-provided JSON or paired CSV export. Its command, safe diagnostics, transaction behavior, and stable `LEGACY_IMPORT_FINGERPRINT_KEY` requirements are documented in the backend repository.
- Flutter runtime and setup no longer contain the old persistence integration. No attempt was made to alter or delete the external production source.

## Learnings

- A repository search for export files found no diary export; the only project JSON matches were the Flutter web manifest and editor configuration. The importer fixture is synthetic test data only.
- The task graph permits later QA planning/execution after task 05 records its source-preserving blocker, since these tasks can verify the new backend independently of production dataset reconciliation.

## Files / Surfaces

- `.compozy/tasks/backend-python-dio/task_05.md` and task workflow state.
- Backend operator procedure: `/home/paulo/Documents/projects/node/my_diary_bk/docs/legacy-import.md`.
- Existing feature/repo source and data were left unchanged.

## Errors / Corrections

- Production count/ID/date/content/access comparisons and representative legacy authentication could not be run because the required consistent source export is missing. Fixture results are not substituted for production evidence.

## Ready for Next Run

- Task 05's safe fallback is satisfied: production migration is explicitly unverified, no source retirement was performed, and the external prerequisite is a complete, consistent operator-provided production JSON export or paired diaries/entries CSV export.
- To finish production reconciliation, an authorized operator must provide the export without exposing secrets in the repository; then run dry-run, resolve all diagnostics, apply transactionally, compare counts/IDs/unique dates/content/access and sampled authentication, and record evidence before source retirement.
- Task 06 can plan QA and task 07 can verify the backend app journeys without asserting production data equivalence. Production migration remains an open risk until export reconciliation passes.
