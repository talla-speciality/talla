# Talla Android product plan

## Existing platform assets discovered

The current Talla workspace already includes a mature iOS app, watch app, widgets, a Node/Postgres backend, Shopify Storefront and Admin integrations, loyalty, address and order APIs, Apple Wallet passes, stock and campaign notifications, multiple payment paths, and BLE scale integrations.

Android should therefore be a native client of the same commerce and customer platform—not a second backend.

## Recommended release scope

### Release 1: commerce and loyalty

- Home merchandising controlled by existing backend settings.
- Shopify catalogue, search/filter, product detail, variants, favourites, and cart.
- Delivery/pickup selection with matching Bahrain and GCC rate rules.
- Hosted Shopify checkout plus Android-compatible BENEFIT, BenefitPay, EazyPay, and MPGS paths where merchant SDKs permit.
- Account creation/login, profile, addresses, order history, Beans balance, reward redemption, stock alerts, and notifications.
- Arabic/English, RTL, light/dark/OLED appearance, and accessibility.

### Release 2: brewing companion

- Guided recipes and timer generated from the existing smart recipe logic.
- Coffee-bag camera/OCR flow.
- Brew journal and taste memory.
- BLE support for BOOKOO, HIROIA JIMMY, GOAT STORY GINA, and MANTABREW WeighMaster 2.0—validated individually against Android BLE behaviour and vendor permissions.

### Release 3: Android ecosystem

- Home-screen widgets, Wear OS companion surfaces, Google Wallet loyalty pass, app shortcuts, and richer notification actions.

## Platform-specific substitutions

| iOS capability | Android counterpart |
| --- | --- |
| SwiftUI | Kotlin + Jetpack Compose |
| Keychain | Android Keystore + encrypted storage |
| App Attest | Play Integrity API |
| APNs | Firebase Cloud Messaging |
| Apple Wallet | Google Wallet |
| Apple Pay | Google Pay or gateway-supported wallet flow |
| WidgetKit | Glance App Widgets |
| watchOS | Wear OS Compose |

## Decisions required before production checkout

- Confirm the production API hostname; the iOS project currently treats it as deployment configuration.
- Obtain Android SDKs/merchant credentials for BenefitPay and MPGS and confirm whether EazyPay exposes an Android-native path.
- Decide whether Shopify remains the customer identity source or the Talla backend becomes the single source of truth.
- Register the final Android application ID, signing key, Play Console account, Firebase project, deep links, and Play Integrity configuration.

## Current Android implementation status

The commerce catalogue, product variants, favourites, persistent bag, hosted Shopify checkout, encrypted Talla accounts, loyalty, orders, vouchers, addresses, stock alerts, guided brewing timer, coffee-bag OCR, local brew journal, shared taste memory, and four Android BLE scale profiles are implemented and compile into the debug APK. Remaining items require platform/merchant credentials, specialist hardware testing, translation QA, or store-release configuration.
