# Backend migration QA report — 2026-10-07

## Result

E2E-001, E2E-002, and E2E-003 passed against the integrated Flutter Web app, Python API, and disposable PostgreSQL instance. E2E-004 is reused from task 04. This verifies synthetic QA data only; production reconciliation and migration are still blocked on a complete operator-provided export.

## Environment

- Flutter Web release build served locally at `http://localhost:8080/` and exercised in headless Google Chrome through CDP at a 1280×900 viewport.
- Python API at `http://localhost:8000/` and PostgreSQL 16 in the disposable `diary-qa` Compose project.
- Synthetic diary `qa browser 1791407263791`; no production credentials or records used.
- Compose lab, browser, HTTP server, and temporary scripts were removed after evidence collection.

## Scenario verdicts

| ID | Verdict | Evidence |
| --- | --- | --- |
| E2E-001 — create/find/unlock/save/reload | PASS | Created a protected diary through the UI, unlocked it, added text through the rich-text editor, saved, and reloaded. The UI showed the saved text; API lookup/unlock/read returned 200 and the entry delta matched. PostgreSQL contained `QA browser persisted entry | browser UI save`. See [reloaded entry](evidence/saved-entry-reloaded.png). |
| E2E-002 — public read-only and denied write | PASS | Set a distinct public password. Public unlock returned `canEdit=false`, read returned 200, direct `PUT` returned 403, and a follow-up read showed unchanged content. Browser rendered the diary in read-only mode without Save or Settings controls. |
| E2E-003 — missing config/service and unsaved retention | PASS | Build without `BACKEND_BASE_URL` started and rendered an in-app configuration message while retaining the diary lookup form ([capture](evidence/missing-backend-config.png)). With the configured API stopped, lookup rendered a retryable communication error ([capture](evidence/unavailable-api.png)). While editing, stopping the API and pressing Save rendered “Não foi possível salvar. Seu texto continua disponível para tentar novamente.” and retained the unsaved marker in the editor ([capture](evidence/failed-save-retains-text.png)). PostgreSQL still held the previously saved entry without that marker; after restarting the API `/health` returned `{"status":"ok"}`. |
| E2E-004 — importer CLI/PostgreSQL | REUSED | Task 04 recorded 28 backend tests passing, including importer CLI and PostgreSQL integration scenarios for dry-run/apply, repeatability, rollback, and credential upgrade. No reason required rerunning unchanged importer code. |

## Build and execution notes

- `fvm flutter --no-version-check build web --release --base-href / --dart-define=BACKEND_BASE_URL=http://localhost:8000` passed before runtime journeys.
- A second release build without a backend define passed and was used for the missing-config browser check.
- Flutter emitted the non-fatal Wasm dry-run suggestion and Cupertino icon font notice on both builds.
- During the final database confirmation, an initial inspection used the wrong local role/table names and failed; corrected inspection with the Compose-defined `my_diary` role confirmed the expected unchanged entry. This was an inspection-command correction, not an application failure.

## Limitations and disposition

- The browser journeys use synthetic records in a disposable local database. They do not prove that real legacy records were exported, reconciled, imported, or preserved in production.
- Task 05 records the sole external blocker: a complete, consistent production export is not available. The existing source must remain intact until import reconciliation succeeds; no production migration or source retirement is claimed.
- Visual captures are retained in this report's `evidence/` directory. No temporary process, container, or database volume is intended to remain running.
