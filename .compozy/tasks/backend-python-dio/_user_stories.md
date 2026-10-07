# User Stories: Dedicated Python Backend for My Diary

Canonical behavior catalog for moving My Diary persistence from Supabase to a dedicated Python backend. Companion to `_spec.md`.

## Personas

- **Diary owner** — a person who creates and writes in a diary and may protect it with a password.
- **Diary visitor** — a person opening a diary made public by its owner, possibly using a public password.

## Story Index

| ID     | Feature Area                     | Persona         | Story                                                        |
| ------ | -------------------------------- | --------------- | ------------------------------------------------------------ |
| US-001 | Diary discovery and creation     | Diary owner     | Find an existing diary or create a new one by name.          |
| US-002 | Diary access                     | Owner / visitor | Open a diary using its configured access rules.              |
| US-003 | Dated diary entries              | Diary owner     | Read and save entries independently for each calendar date.  |
| US-004 | Diary access settings            | Diary owner     | Change public visibility and password protection.            |
| US-005 | Backend connection and failures  | Owner / visitor | Use the diary website with clear feedback when the service fails. |
| US-006 | Existing data migration          | Project maintainer | Migrate existing diaries and entries without losing access. |

## Diary Discovery and Creation

### US-001: Find or create a diary

**As a** diary owner, **I want** to find a diary by name or create it when it does not exist, **so that** I can return to my diary and start using a new one without changing my workflow.

Acceptance criteria:

- AC-1: Given a diary exists with the entered name, when I submit that name, then the website opens that diary and follows its access requirements.
- AC-2: Given no diary exists with the entered name, when I choose to create it and complete the required access fields, then the website opens the newly created diary.
- AC-3: Given diary creation succeeds, when I later search for that same name, then the created diary can be found.
- AC-4: Given creation is rejected or cannot be completed, when the request finishes, then the website communicates failure and does not claim that the diary was created.

Edge cases:

- EC-1: The entered name is blank or invalid under existing validation → the website explains the validation issue and does not create a diary.
- EC-2: Two creation attempts use the same diary name → the existing uniqueness behavior is preserved and the website communicates the result without opening the wrong diary.

## Diary Access

### US-002: Open a diary with its configured access

**As a** diary owner or visitor, **I want** to open a diary using the access rules chosen for it, **so that** private content stays protected while public sharing works as expected.

Acceptance criteria:

- AC-1: Given a private diary has a master password, when I enter the matching password, then the diary opens for editing.
- AC-2: Given a diary requires a password, when I enter a wrong password, then the diary stays closed and the website communicates that access was not granted.
- AC-3: Given a public diary has a public password, when I enter that password, then I can read the diary using the existing public access behavior.
- AC-4: Given public access is read-only, when I open the diary through that path, then I cannot save changes to its entries.
- AC-5: Given a diary has no password requirement, when I open it, then the website permits access consistent with its configured visibility.
- AC-6: Given a diary was migrated with a legacy SHA-256 password hash, when its owner enters the correct password, then access succeeds without requiring a password reset.
- AC-7: Given a migrated diary owner authenticates successfully, when the backend supports stronger password storage, then the owner can continue using the same password after the stored representation is upgraded.

Edge cases:

- EC-1: A backend request fails during access verification → the website reports that access could not be checked and does not treat the diary as authenticated.
- EC-2: Backend responses contain access information → the website never receives password hashes for local authorization.

## Dated Diary Entries

### US-003: Read and save entries by date

**As a** diary owner, **I want** to read and save content for a selected date, **so that** my diary preserves a separate record for each day.

Acceptance criteria:

- AC-1: Given an entry exists for the selected date, when I open that date, then its saved content is displayed.
- AC-2: Given no entry exists for the selected date, when I open it, then I can start with an empty entry.
- AC-3: Given I save content for the selected date and the service confirms success, when I revisit that date, then the saved content is displayed.
- AC-4: Given I save content for one date, when I open another date, then the other date's entry is unchanged.
- AC-5: Given the service does not confirm a save, when the save attempt ends, then the website does not show a successful-save outcome and keeps the current content available for retry.

Edge cases:

- EC-1: A date changes across a timezone boundary → the entry remains associated with the calendar date selected in the diary interface.
- EC-2: A save is repeated after a lost response → the final visible entry for that date is the submitted content, without creating duplicate date entries.

## Diary Access Settings

### US-004: Change diary visibility and passwords

**As a** diary owner, **I want** to change my diary's visibility and access passwords, **so that** I can control who can open it.

Acceptance criteria:

- AC-1: Given I submit valid new access settings, when the service confirms the update, then subsequent diary access follows those settings.
- AC-2: Given I choose public access, when a public password is required by the existing rules, then the website requires it before applying the change.
- AC-3: Given the proposed public password matches the master password, when I submit the settings, then the website rejects the change with a clear validation outcome.
- AC-4: Given I submit invalid settings or the service rejects the update, when the request finishes, then the website communicates failure and does not present the new settings as active.

Edge cases:

- EC-1: The owner leaves an optional password field unchanged → its current value is preserved according to the existing access-setting behavior.
- EC-2: The diary cannot be found when access settings are saved → the website communicates that the update did not take effect.

## Backend Connection and Failures

### US-005: Receive clear feedback when the backend cannot serve a request

**As a** diary owner or visitor, **I want** the website to explain when it cannot reach or use the diary service, **so that** I know whether my action succeeded and what I can retry.

Acceptance criteria:

- AC-1: Given the backend is unavailable, when I search, create, load, save, or update access settings, then the website communicates that the operation could not be completed.
- AC-2: Given a write operation fails, when the failure is shown, then the website does not claim that the data was saved or settings were updated.
- AC-3: Given backend configuration is missing or invalid, when the website starts, then it communicates that the service is unavailable or misconfigured without reverting to Supabase.
- AC-4: Given a backend response denies access, when the website handles it, then protected content is not displayed through an unauthenticated state.

Edge cases:

- EC-1: The response is lost after the backend may have completed a write → retrying the same entry content or access setting leaves the user with the intended final state and no false success message.
- EC-2: Supabase environment variables or client initialization are absent → the website does not require them to start or access the configured backend.

## Existing Data Migration

### US-006: Migrate existing diaries and entries

**As a** project maintainer, **I want** a migration tool that transfers existing Supabase diaries and dated entries into the dedicated backend, **so that** existing diary owners keep their content and access when the website moves to the new service.

Acceptance criteria:

- AC-1: Given a valid source snapshot of the existing diary data, when I run the migration, then the backend contains the diaries and dated entries with their identities, content, dates, visibility, and access behavior preserved.
- AC-2: Given the migration completes, when existing owners open their diaries, then they can authenticate with their current passwords without resetting them.
- AC-3: Given a migration cannot complete or some records are rejected, when the run ends, then its result identifies the outcome and the affected records so the maintainer can resolve the issue without treating incomplete migration as complete.
- AC-4: Given the migration is run again on the same source data, when records are already present, then the tool does not create duplicate diaries or entries.
- AC-5: Given the Flutter website is built or run without Supabase credentials, when it uses the dedicated backend, then existing Supabase SDK setup is not required for normal diary use.

Edge cases:

- EC-1: The source contains records that violate the new backend's constraints → the tool reports those records and does not silently discard them.
- EC-2: A migrated legacy password hash is verified successfully → it may be upgraded by the backend without exposing the hash to the Flutter client or requiring a password reset.
