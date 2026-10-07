---
schema_version: "compozy.tasks/v2"
workflow: backend-python-dio
graph:
  nodes:
    - id: task_01
      file: task_01.md
    - id: task_02
      file: task_02.md
    - id: task_03
      file: task_03.md
    - id: task_04
      file: task_04.md
    - id: task_05
      file: task_05.md
    - id: task_06
      file: task_06.md
    - id: task_07
      file: task_07.md
  edges:
    - from: task_01
      to: task_02
    - from: task_02
      to: task_03
    - from: task_01
      to: task_04
    - from: task_03
      to: task_05
    - from: task_04
      to: task_05
    - from: task_05
      to: task_06
    - from: task_06
      to: task_07
---

# Task Graph: Dedicated Python Backend for My Diary

| # | Title | Status | Complexity | Dependencies |
|---|---|---|---|---|
| 01 | Python API, PostgreSQL, and access policy | pending | high | — |
| 02 | Flutter Dio client and repository adapter | pending | high | 01 |
| 03 | Wire backend workflows and remove Supabase runtime | pending | high | 02 |
| 04 | Build the repeatable legacy data importer | pending | high | 01 |
| 05 | Reconcile migrated data and retire Supabase setup | pending | critical | 03, 04 |
| 06 | QA plan and session charters | pending | medium | 05 |
| 07 | Real-user and API journey QA | pending | high | 06 |

## MVP Boundary

Tasks 01-05 implement the backend migration, Flutter integration, importer, and verified Supabase retirement. Tasks 06-07 plan and execute remaining integration QA.
