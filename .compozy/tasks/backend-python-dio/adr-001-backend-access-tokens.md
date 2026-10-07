# ADR-001: Backend-enforced diary access and token sessions

## Status

Proposed

## Date

2026-10-07

## Context

The current Flutter Supabase repository selects password hashes and the browser compares them locally. This exposes verifier material and makes client-side `canEdit` the effective access boundary. Replacing Supabase with a dedicated API must preserve accountless diary access while ensuring entry content and access changes are authorized by a server. Public password access must remain read-only; master-password access must allow editing.

## Decision

The Python backend verifies master/public passwords, never returns password hashes, and issues a short-lived signed bearer token scoped to one diary and a `read` or `write` permission. Every entry/access endpoint validates token signature, expiry, diary scope, and required permission. Flutter holds the token in memory for the active session and uses response `can_edit` only to render the UI. New and updated secrets use Argon2id. Imported plaintext or SHA-256 credentials are verified through a compatibility path and upgraded to Argon2id after successful verification.

## Alternatives Considered

### Alternative 1: Return hashes and keep local password comparison

- **Description**: Preserve Flutter verification and use HTTP only for CRUD.
- **Pros**: Minimal changes to core/view-model behavior.
- **Cons**: Exposes verifier hashes to every browser; allows a modified client to bypass read-only controls; backend cannot distinguish owner from visitor.
- **Why rejected**: Fails the required server-owned access boundary and security requirement.

### Alternative 2: Add user accounts and an identity provider

- **Description**: Replace diary passwords with account login and user/role associations.
- **Pros**: Standard account lifecycle, revocation, and identity model.
- **Cons**: Changes current accountless product workflows, requires account migration, and introduces an out-of-scope identity system.
- **Why rejected**: Product retains current diary access behavior and excludes account creation/social login.

### Alternative 3: Issue a permanent diary token

- **Description**: Keep bearer credentials indefinitely or persist them in browser storage.
- **Pros**: Fewer unlock requests.
- **Cons**: Stolen tokens remain usable indefinitely; persistent storage increases exposure.
- **Why rejected**: Bounded exposure is preferred; short TTL and in-memory storage fit current session flows.

## Consequences

### Positive

- Password hashes are never exposed to the browser.
- Read-only and write access are enforced by the service even if client UI code is modified.
- Existing users continue with legacy passwords and upgrade without reset.

### Negative

- Flutter retains a token for the active diary and handles expiration/re-unlock.
- Backend signing-key provisioning and rotation become operational responsibilities.
- Hash verification and token validation add backend dependencies and test requirements.

### Risks

- Token theft grants scoped permission until expiry. Mitigate with HTTPS, 15-minute expiry, strict CORS, no persistent browser storage, and authorization on every request.
- Legacy SHA-256 compatibility remains less resistant until each user authenticates. Restrict export access and rehash after successful login.

## Implementation Notes

- Default token lifetime is 15 minutes.
- Password verification uses constant-time comparison where applicable.
- API errors must not reveal whether a supplied password matched a stored verifier.
- The migration importer accepts exported data only; it does not add a runtime Supabase client.

## References

- [Feature specification](_spec.md)
- [HTTP/API and importer contract](_dx.md)
- Existing password representation: `lib/core/security/password_hasher.dart` in the Flutter repository.
