# iOS 27 readiness

For the subsequent conventional iPhone/iPad layout changes and device matrix, see [iOS 27 device optimization](IOS_27_DEVICE_OPTIMIZATION.md). iPhone Duo validation remains deferred to 27.1.

## Compatibility changes

- Pin Xcode 27.0 in `.xcode-version` and build with the iOS 27 SDK.
- Use GitHub's `xcode-27` Apple silicon runner. Select the pinned Xcode explicitly and check the iOS SDK version.
- Require an available iOS 27 iPhone simulator for CI unit and UI tests. Older runtimes must not silently satisfy this check.
- Make the app and widget brew Live Activity attributes and content state explicitly `nonisolated` and `Sendable`. These value-only payloads cross ActivityKit concurrency boundaries; inheriting the app's default main-actor isolation produced Xcode 27 warnings.
- Add a regression test that transfers and JSON-round-trips the Live Activity payload in a detached task.
- Retain iOS 17 and watchOS 10 deployment targets. Existing iOS 26 presentation features remain availability-gated and also apply on iOS 27.

The customer app and admin app already use SwiftUI `App` / `WindowGroup` and generated scene manifests, satisfying the scene lifecycle requirement. No lifecycle rewrite or compatibility-mode opt-out is needed.

## Visual adaptation

- The customer app's iOS 26+ tab bar and iOS 27 navigation toolbar defer to system Liquid Glass materials instead of forcing an opaque brand-colored background. This allows the user's clear-to-tinted Liquid Glass preference to remain visible.
- Primary customer sheets use the system presentation container with a 28-point corner radius on iOS 26+; custom content backgrounds remain inside the sheet and do not replace the system material.
- Product detail, social coffee, gift vault, favourites, rewards, concierge, account, checkout payment/address, and espresso sheets use the shared presentation treatment. The iOS 17 fallback retains the existing background behavior.
- The iOS 27 navigation toolbar exposes the bag action and appearance/language menu through standard toolbar placements. The More screen's navigation typography uses the app's Dynamic Type-aware font helpers.

Validate the visual paths on iOS 27 with Liquid Glass set to both ultra-clear and fully tinted, in light, dark, and OLED appearance modes, including Arabic and larger accessibility text sizes. Confirm tab labels, toolbar actions, close controls, and sheet content remain legible while scrolling.

## Validation

Validation used local Xcode 27.0 (27A266a), iOS SDK 27.0 and watchOS SDK 27.0. The iPhone app, physical-device build, Watch app, and simulator test bundle all built successfully. On a clean iOS 27 simulator, all 108 unit tests passed, including the Live Activity concurrency regression test. The three previously affected UI journeys also passed: Arabic checkout reached the localized right-to-left checkout, English checkout observed both authenticated mock order and payment requests, and offline recovery showed cached data before retrying successfully. Account deletion, Bluetooth recovery, and startup-with-network-stall remain passing from the earlier validation run.

## Physical-device release checks

Before store submission, verify payment handoff and callbacks (BenefitPay, hosted checkout, Apple Pay and card flows), Bluetooth scales, NFC, push notifications, and Live Activity / Watch continuity on physical devices. Simulator UI tests use the project's local test server and cannot prove provider or hardware integration. Signed archive and App Store submission are separate release steps.

## iPhone Duo preparation

The app already targets both iPhone and iPad, uses SwiftUI size classes, standard `TabView`, scroll views, sheets, menus, and safe-area-aware foreground content. The root layout also responds to compact height. Regular-width grids now adapt to available width and text size; fold-specific behavior has not been validated.

Full iPhone Duo validation requires Xcode 27.1 and its Device Hub simulator. When that SDK is available, test the outer display, fully open inner display, partially folded book and tabletop poses, rotation, and Split View. Confirm the system places the tab bar vertically, foreground controls avoid asymmetric safe areas and reserved camera/hinge regions, and state remains unchanged while opening and closing the device.

## Sources

- [Apple iOS & iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes)
- [Apple Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)
- [GitHub Xcode 27 runner availability and paths](https://github.com/actions/runner-images/issues/14404)
- [Apple: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Apple: Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
