# iOS 27 and iPadOS 27 device optimization

Scope: the customer app on conventional iPhones and iPads. iPhone Duo work is deferred until the Xcode/iOS 27.1 update, as requested. The deployment target remains iOS 17.

## Changes

- Arabic system fonts now scale with Dynamic Type using the same semantic text categories as the English custom fonts.
- Product, collection, and brewing grids adapt their column count to available width. Accessibility sizes reduce compact layouts to one column where needed, including account actions.
- Product text rows grow with their content; quick-drink cards widen at accessibility sizes. Category controls have a minimum 44-point height.
- Checkout uses a centered, maximum 720-point content width. The footer scrolls with the order in short windows and at accessibility sizes, so it cannot occupy the whole viewport.
- The payment total stacks at accessibility sizes, the action label can wrap, and payment-method descriptions are no longer restricted to one line. Arabic checkout explicitly inherits the selected language and right-to-left direction.
- Provider presentation is queued until the checkout full-screen cover finishes dismissing, rather than changing both presentations in the same render.
- Brew Live Activities use ActivityKit authorization and availability rather than excluding iPads by device idiom.

## Automated coverage

`tools/check-ios-device-matrix.py` builds once, creates or reuses dedicated Talla QA simulators, runs tests sequentially, and writes logs, screenshots, result bundles, and a JSON summary. It requires an iOS 27 runtime and verifies the expected number of passing tests with no skips. It restores initially shut-down QA simulators to the shut-down state.

| Matrix entry | Simulator | Coverage purpose |
| --- | --- | --- |
| small-phone | iPhone SE (3rd generation) | Shortest supported conventional phone display |
| mini-phone | iPhone 13 mini | Compact phone with display safe areas |
| phone | iPhone 18 Pro | Standard modern phone |
| large-phone | iPhone 18 Pro Max | Largest conventional phone class |
| mini-ipad | iPad mini (A17 Pro) | Small tablet |
| ipad | iPad (A16) | Standard tablet |
| pro-ipad | iPad Pro 11-inch (M5) | Medium Pro tablet |
| large-ipad | iPad Pro 13-inch (M5) | Large tablet |

The layout suite exercises checkout in portrait, landscape, and portrait again; Arabic at maximum accessibility text size; visible mock payment-page handoff; tab navigation; and search/keyboard state preservation. CI runs these tests on all eight screen classes. Without `--layout-only`, the script also runs the six existing checkout, Arabic, account deletion, offline recovery, Bluetooth interruption, and startup journeys.

These are representative screen classes, not physical testing of every hardware SKU. iPad Air models share the adaptive tablet layout paths. Rotation tests are not a substitute for live window-resizing tests.

## Local verification

Local matrix validation is in progress. Final result paths and counts will be recorded after completion.

## Physical-device follow-up

Simulator tests use the local mock service and do not place production orders or charge cards. Live provider settlement, Apple Pay/BenefitPay/3-D Secure callbacks, physical Bluetooth scales, NFC, APNs delivery, Live Activity rendering on real iPads, window resizing, and memory/energy performance on older supported hardware still require device validation. No store submission or release signing is part of this change.
