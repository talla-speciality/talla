# Phase 1 completion

This is the acceptance checklist for the iOS, watchOS, widget, Android, and backend release/data foundation. A checked item means the behavior is implemented and covered by a local or CI verification path. Provider credentials and live alert destinations remain deployment configuration; they are never committed.

## 1. Coffee data foundation

- [x] iOS uses SwiftData and Android uses SQLite for offline coffee records.
- [x] Coffee lots, purchased products, roast date, and remaining quantity are modeled.
- [x] Brewers, machines, baskets, grinders, calibrations, and maintenance events are modeled.
- [x] A recipe edit creates an immutable, incrementing recipe version on both clients.
- [x] Filter and espresso sessions persist weight, flow, pressure, and temperature samples plus taste feedback.
- [x] Existing recipe, journal, equipment, and calibration JSON is imported once into the new store.
- [x] Signed-in records synchronize through `/coffee-data/sync`; optimistic revisions detect concurrent edits and retain the rejected local payload for explicit recovery.
- [x] Offline state keeps cached records usable and exposes a real retry path.

Acceptance tests cover recipe immutability, all four sample kinds, one-time migration, conflict behavior, and offline recovery.

## 2. Release pipeline and observability

- [x] The release workflow selects full Xcode and builds the iPhone app, embedded Watch app, iPhone widget, and Watch widget.
- [x] CI runs Apple unit/UI tests, Android unit/instrumented tests and lint, backend lint/tests, and migrations twice for idempotency.
- [x] Tagged builds package checksummed backend artifacts; every build uploads checksummed unsigned Apple QA apps and Android APK/AAB artifacts.
- [x] iOS reports uncaught failures and MetricKit diagnostics/performance; Android reports uncaught failures, launch timing, and lifecycle retention to the backend telemetry store.
- [x] Checkout/payment-funnel, purchase completion, brew completion, rating, and daily retention events are emitted by both clients.
- [x] The unused nested Shopify starter was removed from supported development; the production Shopify integration remains in commerce modules.

## 3. Module boundaries

- [x] `ContentView.swift` was reduced from 16,150 lines to a guarded composition root; commerce, brewing, loyalty, account, and observability behavior is split into feature modules.
- [x] `BrewingSectionView.swift` was reduced from 9,393 lines to a guarded navigation/state shell; setup, recipes, guided brewing, runtime, coffee library, and espresso profiles are separate modules.
- [x] `backend/server.js` was reduced from 12,408 lines and delegates routing and domain behavior to application, commerce, brewing, loyalty, account, and observability modules.
- [x] Lint enforces entry-point line budgets so feature code cannot silently return to the roots.

## 4. Release hardening

- [x] Customer sessions use hashed access/refresh credentials, single-use refresh rotation, and whole-family revocation on reuse or expiry.
- [x] Admin roles map to explicit permissions and every sensitive route enforces its required permission.
- [x] A nightly workflow creates an encrypted Postgres backup and proves it restores into isolated PostgreSQL before uploading it.
- [x] External health checks run every five minutes; a manual delivery-test option proves the configured alert webhook accepts notifications.
- [x] The production secret rotation policy defines owners, intervals, overlap, verification, revocation, and incident rotation.
- [x] Apple deployment targets are iOS 17 and watchOS 10 instead of iOS 26-only.
- [x] UI tests exercise the production checkout, Arabic localization, confirmed account deletion, cached offline recovery, and Bluetooth interruption/reconnect paths using stable accessibility identifiers.

## Deployment gates

Before a production release, the release owner must verify the latest `Release pipeline`, `Database resilience`, and `External uptime` runs on `main`; manually dispatch the alert delivery test; verify a staging backend 5xx reaches the Render `OPS_ALERT_WEBHOOK_URL`; and complete any secret rotation due under `docs/SECRET_ROTATION.md`. Any credential exposed in chat, logs, or tickets must be rotated before release.
