# Code organization

The repository is organized by product target, feature, and responsibility.
Within the main iOS feature areas, files are separated into `Views`, `Models`,
and `Services` so user interface, data types, and side effects have distinct
sections.

## Main iOS app

| Section | Purpose |
| --- | --- |
| `Talla Speciality/App` | App entry point, root navigation, previews, and split `ContentView` extensions (`Models`, `Catalog`, `Lifecycle`, `Presentation`, and `Navigation`) |
| `Talla Speciality/Shared` | Shared models, UI components, and content helpers |
| `Talla Speciality/Features/Account/{Views,Models,Services}` | Account UI, account data, and customer/session APIs |
| `Talla Speciality/Features/Brewing/{Views,Models,Services}` | Brewing UI, brew/coffee data, and recipe/device helpers |
| `Talla Speciality/Features/Commerce/{Views,Services}` | Shop, cart, checkout, payment, and commerce support |
| `Talla Speciality/Features/Discovery/Views` | Coffee map and expert companion experiences |
| `Talla Speciality/Features/Espresso/{Views,Models}` | Espresso workspace and machine/profile models |
| `Talla Speciality/Features/Loyalty/{Views,Services}` | Loyalty UI and loyalty APIs |
| `Talla Speciality/Services/Devices/{Drivers}` | Scale manager and vendor-specific Bluetooth drivers |
| `Talla Speciality/Services/Observability` | Notifications and observability UI |
| `Talla Speciality/Services/Platform/{AI,Security,System}` | Concierge AI, App Attest, HealthKit, refresh, Spotlight, and telemetry |
| `Talla Speciality/Shared/{Models,UI,Support}` | Shared data types, reusable UI, and app-wide helpers |

## Other targets

- `Talla Admin`: native admin application and admin workspace code.
- `Talla Watch Watch App`: Apple Watch application and tests.
- `Talla Watch Widgets`: Apple Watch widget extension.
- `Talla Widgets`: iPhone widget extension and App Intents.
- `Talla SpecialityTests` and `Talla SpecialityUITests`: main app tests.

## Backend and Android

- `backend/modules`: backend code grouped by account, application, brewing,
  commerce, discovery, loyalty, and observability.
- `backend/test`: backend tests grouped as one test per behavior/module.
- `android/app/src`: Android application source and resources.

The Xcode project uses filesystem-synchronized groups, so the folder structure
is reflected automatically in the project navigator. New main-app code should
be added to the matching `Features`, `Services`, `Shared`, or `App` section
instead of the target root.
