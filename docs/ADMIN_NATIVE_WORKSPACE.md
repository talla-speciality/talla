# Native admin workspace

The admin app now has five tabs: Orders, Products, Customers, Admin, and Settings. The Admin tab opens native SwiftUI screens for App Home, Live Controls, Seasonal Events, Coffee Passport, Notifications, Analytics, Operations, Taste Memory, and Recent Admin Actions. The old web console is no longer routed from the app.

Products includes status/category filters, search, sorting, product creation, profile/price/badge edits, image URL entry, inventory adjustment with the backend's comparison quantity, and confirmed deletion. Customers includes account/tier/loyalty filters, profile editing, loyalty adjustments, vouchers, addresses, order details, session/account actions, bulk vouchers, and native CSV export.

Content edits remain drafts until Publish. Leaving a changed content screen asks before discarding it. Before replacing a settings document, the app checks whether the server copy changed since it was loaded. This detects intervening edits but is not atomic concurrency control: the backend does not expose conditional writes, so a change between the check and POST can still race.

All screens use the existing authenticated admin APIs. Unauthorized responses return to sign-in. Loading failures retain existing data and provide retry/refresh. Notifications display a preview and require an in-app confirmation before sending. No live messages, store updates, or customer changes were made during development.

## Verification

- Xcode Debug simulator build for the Talla Admin scheme.
- Standalone native model checks: `bash tools/check-admin-models.sh`.
- Model checks cover preserving unknown/nested server fields, JSON types, numeric validation, negative loyalty adjustments, managed links, version/color formats, fractional-second server timestamps, and plus-addressed customer lookup.
- iPhone Air simulator with a localhost fixture backend: visually inspected the native Admin menu, product list, product details, and inventory form; edited the sample quantity.
- Live Shopify writes, production customer mutations, notification delivery, and physical-device behavior were not exercised. Simulator UI automation could not reliably activate navigation-bar coordinates, so end-to-end save confirmations were not verified through the UI.

## Build

```sh
xcodebuild -project 'Talla Speciality.xcodeproj' -scheme 'Talla Admin' \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

No backend deployment or App Store/TestFlight release is included. Catalog enumeration retains the backend's existing 250-product limit.
