# Code organization

The repository is organized by product target and feature. Files that belong to
the same user-facing area live together, while platform integrations and shared
UI stay separate.

## Main iOS app

| Section | Purpose |
| --- | --- |
| `Talla Speciality/App` | App entry point, root navigation, previews, and split `ContentView` extensions (`Models`, `Catalog`, `Lifecycle`, `Presentation`, and `Navigation`) |
| `Talla Speciality/Shared` | Shared models, UI components, and content helpers |
| `Talla Speciality/Features/Account` | Sign-in, customer account, and account workspace |
| `Talla Speciality/Features/Brewing` | Brewing flows, recipes, coffee library, and coffee education |
| `Talla Speciality/Features/Commerce` | Shop, cart, checkout, and payment flows |
| `Talla Speciality/Features/Discovery` | Coffee map and expert companion experiences |
| `Talla Speciality/Features/Espresso` | Espresso profiles, machine models, and DE1 integration |
| `Talla Speciality/Features/Loyalty` | Loyalty views and loyalty service |
| `Talla Speciality/Services/Devices` | Connected scale drivers and device managers |
| `Talla Speciality/Services/Observability` | Notifications and observability UI |
| `Talla Speciality/Services/Platform` | App Attest, HealthKit, telemetry, and concierge services |

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
