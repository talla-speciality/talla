# iOS bug-fix verification — 2026-09-08

## Changes made in this audit

- Fixed a saved-login startup loop. The credential getter removed a legacy UserDefaults key on every read, even after migration. Those notifications could repeatedly invalidate SwiftUI during ContentView initialization. It now removes the key only when present. A sampled stalled simulator process identified this path; a regression test verifies repeated credential reads do not broadcast defaults changes.
- Preserved credentials when refresh receives a temporary server error, malformed JSON, or empty tokens. HTTP 401 still invalidates the matching session.
- Discarded refresh responses after sign-out or replacement of the login, preventing late responses from restoring or clearing another session.
- Changed foreground credential restoration to read the authoritative Keychain token instead of overwriting it with the view's stale token. Push unregistration also uses the current token.
- Changed stock-alert save/delete failures to show an error and retain the prior local state instead of displaying success.
- Added session regression tests and isolated coffee-sync batching/paging test preferences. The latter previously inherited account ownership from earlier runs and could clear their own fixtures.

Existing changes to startup presentation, observability fixtures, and UI tests were preserved. This report does not attribute those earlier changes to this audit.

## Verification

- Final unit run: 71 tests passed, zero failed or skipped (72 executions including parameterized cases).
- UI scenarios passed on the final app code: authenticated checkout reaching mocked order/payment endpoints, Arabic checkout, account deletion confirmation, offline recovery, simulated Bluetooth interruption, and startup with stalled network requests. Launch tests also passed.
- Debug simulator build passed, including embedded Watch/widget dependencies.
- Final physical-iPhone Release build passed with code signing disabled. This verifies compilation and linking, not distribution signing or installation on a phone.
- Git diff whitespace validation passed.

Result bundles:

- `/private/tmp/talla-ios-audit-tests-3.xcresult`: final app code UI checks and session regression coverage. This run had one coffee-sync fixture-isolation failure, subsequently corrected.
- `/private/tmp/talla-ios-audit-tests-4.xcresult`: final unit suite after fixture isolation; all passed.

The first unsigned unit run could not store Keychain fixtures. Signed simulator tests resolved that setup problem and exposed the startup loop described above. The earlier Watch preview-macro error was a sandbox artifact: the normal-access build passed without changing the preview.

## Remaining verification limits

These checks do not establish that every possible bug is absent. Live payment settlement, physical Apple Pay/BenefitPay/3-D Secure flows, real Bluetooth scales, push delivery, App Attest on a physical device, and physical Watch behavior still require device/service validation. The checkout UI tests use local mock services and do not charge customers or place production orders. No backend changes were made in this iOS audit.
