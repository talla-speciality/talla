# Talla Android

Native Android foundation for Talla Speciality, built with Kotlin and Jetpack Compose.

## Implemented

- Talla-branded Home, Shop, Brewing, and Account destinations.
- Live Shopify Storefront product catalogue.
- Search, category filters, product details, variants, favourites, recent views, and remote product imagery.
- Persistent shopping bag with quantity controls.
- Cash-on-delivery ordering through Shopify hosted checkout for delivery or pickup, including signed-in address prefill.
- Hosted BENEFIT debit-card checkout with server-side encrypted requests and payment verification.
- Mastercard Click to Pay hosted checkout with Android return deep link and verified order status.
- BenefitPay Android SDK flow with backend-issued sessions and server-side confirmation.
- Bahrain and GCC shipping-rate rules with unit tests.
- Encrypted customer sessions with registration, login, automatic restore, and logout.
- Live loyalty Beans, tiers, rewards, vouchers, orders, addresses, and stock alerts from the Talla backend.
- Address creation/deletion and a favourites shelf.
- Guided brew recipes for six methods with adjustable dose/ratio, step targets, and timer.
- A persistent coffee journal prefilled from guided brews, with ratings, recipe details, and tasting notes.
- Shared taste memory on completed orders, synced with the same backend used by iOS.
- Camera and photo-library coffee-bag scanning with bundled on-device OCR and structured label extraction.
- Bluetooth discovery and live brewing telemetry for BOOKOO Themis, MANTABREW WeighMaster 2.0, HIROIA JIMMY, and GOAT STORY GINA scales.
- English and Arabic resources, automatic RTL layout, and an in-app language selector.
- Light and dark colour schemes.

## Open the project

1. Open the repository's `android` directory in Android Studio.
2. Allow Android Studio to install Android SDK 37 if it is not already present.
3. Sync the Gradle project.
4. Run the `app` configuration on an emulator or physical device running Android 8.0 or newer.

The Gradle wrapper uses Android Studio's bundled Java runtime automatically on macOS.

## Configuration

Defaults live in `gradle.properties`. For private/local overrides, put these values in `~/.gradle/gradle.properties`:

```properties
TALLA_SHOP_DOMAIN=duneroastery.myshopify.com
TALLA_STOREFRONT_TOKEN=your-storefront-token
TALLA_BACKEND_URL=https://api.tallaspeciality.com
```

The Shopify Storefront token is a public client credential. Payment gateway secrets and Shopify Admin credentials must remain exclusively on the backend.

## Local payment SDK setup

The proprietary merchant SDK binaries are deliberately excluded from Git. Before the first Gradle sync, install the authorized vendor files locally:

```text
android/app/libs/benefitinappsdk-1.0.27.aar
android/gateway-repo/com/mastercard/gateway/Mobile_SDK_Android/2.0.17/...
android/gateway-repo/com/mastercard/gateway/gateway-android-3ds/6.7.60/...
```

Use the AAR and local Maven repository supplied directly by BENEFIT/FOO and Mastercard. Do not commit merchant SDKs, keystores, `local.properties`, or production credentials.

## Remaining production milestones

1. Enable the final merchant credentials and provider approvals for BENEFIT, BenefitPay, Click to Pay, native MPGS card, and Google Pay.
2. Firebase Cloud Messaging and Android Play Integrity verification on sensitive backend routes.
3. Physical validation of the supported Bluetooth scales and enhanced Arabic-script OCR.
4. Arabic resources and RTL QA, accessibility pass, analytics/privacy review, and Play Store release preparation.
5. Google Wallet, widgets, and Wear OS surfaces.

The existing iOS source was used as product and platform reference only. It was not modified.
