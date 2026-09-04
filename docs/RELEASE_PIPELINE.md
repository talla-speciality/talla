# Talla release pipeline

The GitHub Actions release pipeline validates the backend, PostgreSQL migrations, iPhone app, iPhone widget, Watch app, Watch widget, and Android app on every pull request and `main` push. A `v*` tag also packages the backend. Mobile jobs retain unsigned QA artifacts; App Store and Play Store signing remains in the stores' protected release systems.

## Required checks

- `backend`: Node 22 install, JavaScript lint, ordered migration validation, two migration passes against PostgreSQL 18, and the complete test suite.
- `android`: JDK 17, unit tests, Android lint, and unsigned release APK/AAB artifacts. CI substitutes compile-only BenefitPay interfaces because proprietary merchant SDK binaries must not be committed.
- `apple`: full Xcode 26.6, iPhone Release build and tests, Watch Release build, iPhone widget build, and Watch widget build.

Protect `main` in GitHub and require all three jobs. Create releases from annotated `vMAJOR.MINOR.PATCH` tags only after the QA artifacts pass device testing.

## Local verification

The repository pins Xcode in `.xcode-version`. On a Mac with Xcode installed:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
cd backend && npm run verify
cd ../android && ./gradlew -Ptalla.ci=true testDebugUnitTest lintDebug assembleRelease bundleRelease
```

Run each shared Xcode scheme with `CODE_SIGNING_ALLOWED=NO` before a release. Production archive signing still requires the Talla Apple team and the authorized BenefitPay framework.

## Telemetry contract

Both mobile apps buffer telemetry offline and post bounded batches to `/telemetry/events`. The backend accepts only allow-listed platforms/categories, strips sensitive property names, limits event/property sizes, and stores data in `telemetry_events` through migration `025_mobile_telemetry.sql`.

Tracked product outcomes include:

- checkout started, payment method selected, payment funnel stage, payment failure, and purchase completion;
- completed brew, completed timer, brew rating, and daily active retention;
- app launch duration, MetricKit performance payloads, MetricKit diagnostics, Android uncaught exceptions, and unclean foreground exits.

No payment token, card data, password, authorization value, or customer email is accepted in mobile event properties. Server-generated checkout events can associate an authenticated account through a protected database column.

## Production release gates

1. Verify App Store and Play Store privacy disclosures cover product analytics and diagnostics.
2. Apply migrations before serving a backend version that writes new event types.
3. Validate BenefitPay, BENEFIT, card, Apple Pay, and Click to Pay on physical devices with production-approved credentials.
4. Download and retain dSYMs, mapping files, signed IPA/AAB, checksums, and store submission metadata for each release.
5. Confirm `/health` returns `200` and `/telemetry/events` returns `202` for a valid synthetic event after deployment.
