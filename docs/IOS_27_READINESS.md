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

## Validation

Validation used local Xcode 27.0 (27A266a), iOS SDK 27.0 and watchOS SDK 27.0. The iPhone app, physical-device build, Watch app, and simulator test bundle all built successfully. On the newly installed iOS 27 simulator, all 84 unit tests passed, including the Live Activity concurrency regression test. Three of six existing UI journeys were affected by simulator automation timing or fixture behavior: Arabic checkout did not reach its screen before the timeout, English checkout did not observe the mock payment request, and offline recovery timed out querying accessibility. Account deletion, Bluetooth recovery, and startup-with-network-stall passed.

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
