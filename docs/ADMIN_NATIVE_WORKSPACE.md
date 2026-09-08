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

### Variant display checks

```swift
let oldItem = try JSONDecoder().decode(AdminOrderItem.self, from: Data(#"{"name":"Coffee - Large","quantity":1}"#.utf8))
expect(oldItem.displayName == "Coffee - Large", "Legacy order names remain visible")
expect(oldItem.variantDescription == nil, "Do not invent variants for old orders")

let sizedItem = try JSONDecoder().decode(AdminOrderItem.self, from: Data(#"{"name":"Cup - Large","productTitle":"Cup","quantity":2,"variantTitle":"Large","selectedOptions":[{"name":"Size","value":"Large"}]}"#.utf8))
expect(sizedItem.displayName == "Cup", "Product name does not repeat variant")
expect(sizedItem.variantDescription == "Size: Large", "Show purchased size by name")

let coffee = AdminOrderItem(name: "Coffee", quantity: 1, variantTitle: "250g / Whole Bean")
expect(coffee.variantDescription == "250g / Whole Bean", "Shopify order snapshot title is displayed")

let plain = AdminOrderItem(name: "Coffee", quantity: 1, variantTitle: "Default Title", selectedOptions: [.init(name: "Title", value: "Default Title")])
expect(plain.variantDescription == nil, "Hide default variant placeholders")

let options = AdminOrderItem(
    name: "Coffee",
    quantity: 1,
    selectedOptions: [
        .init(name: "Weight", value: "250g"),
        .init(name: "Grind", value: "Whole Bean")
    ]
)
expect(options.variantDescription == "Weight: 250g · Grind: Whole Bean", "Show all purchased options")
```

## Purchased product variants

Order cards and details show the product name with the purchased variant/options underneath, and order search also matches variants and SKU. Verified checkout snapshots obtain these fields from Shopify alongside authoritative pricing. Legacy checkout clients use a best-effort catalog lookup at checkout time. Shopify webhook/sync imports retain the line item's purchase-time variant title, including when its catalog variant was deleted. Default Title placeholders are suppressed. Historical orders without recorded variant data keep their original item names; no current-catalog guesses are made.

This addition requires deploying the backend changes and installing the rebuilt admin app. No database migration is required because item metadata is stored in the existing order JSON. Coverage includes Shopify import mapping, checkout snapshot metadata, default/missing variants, and native display compatibility.
