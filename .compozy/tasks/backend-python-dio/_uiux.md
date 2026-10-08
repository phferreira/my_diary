# UI Change Map: Dedicated diary backend

The feature keeps the existing visual design and primary diary journeys. No new screen or navigation is introduced.

| Screen | Change | Required behavior |
|---|---|---|
| App startup / login | Surface missing or invalid `API_BASE_URL` and backend connection failures. | Do not silently start an in-memory/Supabase repository; keep the login form usable for retry after transient failure. |
| Diary lookup/create | Show backend validation, duplicate-name, and unavailable-service outcomes. | Do not navigate into a diary after a failed operation. |
| Diary unlock | Show generic invalid-password feedback and service failure separately. | Do not expose hashes or treat a failed unlock as authenticated. |
| Diary editor | Keep current editor content visible after failed load/save and show a failure message. | Only show save success after API confirmation; respect server-derived `can_edit` for controls while server enforces it independently. |
| Access settings | Keep the existing dialog and validation feedback. | Reflect new settings only after confirmed API success; public-password access remains read-only. |

Responsive layouts, typography, visual assets, and accessibility semantics remain as currently implemented. QA should exercise failure messages on mobile and desktop widths and ensure editor content is not discarded on a network error.
