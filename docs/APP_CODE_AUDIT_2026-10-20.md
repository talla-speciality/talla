# Apple app audit — 2026-10-20

Scope: repository-wide textual scan of 114 Swift files (65,799 lines), targeted review of account lifecycle, catalog caching, admin authentication, concierge, project configuration, and unused declarations. This is not a proof that every execution path is correct. No application source was changed. Existing working-tree changes were preserved.

## Findings

1. **High — late account responses can repopulate signed-out or different-account state.** `ContentView+AccountServices.swift:333–368`, `:685–705`, and `:733–740` check identity before awaiting but not after. `signOutCustomer` clears state without cancelling those requests. A successful response arriving after sign-out can restore the old profile, orders, or addresses; loading orders also reindexes Spotlight after logout has cleared it. `AccountService.data(for:)` returns successful responses without verifying the current session. Capture a session generation and reject stale success/error results before updating state; cancel associated tasks when identity changes. This is a code-path finding, not a reproduced device test.

2. **Medium — catalog cache is not language-specific.** `TallaBackgroundRefresh.swift:69–91` uses one `catalog-products.json` file without a locale. `ContentView+AccountServices.swift:1062–1066` accepts that cache after any fetch failure. Load the English catalog, switch to Arabic offline, and the cached English catalog can replace the requested Arabic catalog (and vice versa). Key cached entries by effective language and avoid marking stale fallback data as freshly fetched.

3. **Medium — Admin logout leaves biometric UI enabled.** `AdminSession.swift:182–196` removes the biometric credential but does not set `biometricEnabled = false`. `AdminLoginView.swift:80` uses that flag to expose biometric sign-in, and the deleted credential makes that action fail. Reset the flag during logout, using the existing `disableBiometricLogin()` helper.

4. **Low — compiler concurrency warnings in tests.** Build-for-testing succeeded, but the warning log contains 10 actor-isolation warnings from assertions in `Talla_SpecialityTests.swift:35`, `:89–91`, `:107–108`, and `:119–122`. The tests access main-actor-isolated product/result values from a nonisolated context. Several diagnostics become errors in Swift 6 language mode. Give the relevant tests appropriate actor isolation.

## Dead code

Confirmed examples with no Swift references outside their declarations:

- `LambIconView`, `SummaryValueRow`, and `ToastBannerView` in `Shared/ContentUIComponents.swift`.
- Private `CoffeeRegionContour` in `Features/Discovery/GulfCoffeeMapView.swift:1079`.
- Private `foundationModelOutput` and `isGenericDeflection` in `Services/Platform/CoffeeConciergeService.swift:728` and `:800`. The recommendation entry point never calls the Apple Foundation Models implementation. The private `ConciergeIntent` generated type also has no explicit use.
- `homeShortcutCard`, `homePersonalizedProductCard`, and `homePersonalizedActionCard` in `Features/Commerce/ContentView+Home.swift`.

The following inventory contains single-occurrence declaration names after excluding recognized app entry points, App Intents, previews, and framework callbacks. It is a conservative textual candidate list, not compiler-index reachability analysis. Some entries may be intentionally reserved APIs; inspect intent before removal. Conversely, mutually referenced dead code and unused overloads can be missed. Do not automatically delete declarations merely because they appear here.

| Declaration | Location |
| --- | --- |
| `moreFeatureTile` | `Talla Speciality/App/ContentView+Presentation.swift:948` |
| `paymentMethodChip` | `Talla Speciality/Features/Commerce/ContentView+CartAndProductViews.swift:1678` |
| `bundledLoyaltyPass` | `Talla Speciality/Features/Commerce/ContentView+CommerceActions.swift:1369` |
| `formattedBHD` | `Talla Speciality/Features/Commerce/ContentView+CommerceActions.swift:1388` |
| `initiateAuthentication` | `Talla Speciality/Features/Commerce/PaymentFlow.swift:1143` |
| `authenticatePayer` | `Talla Speciality/Features/Commerce/PaymentFlow.swift:1166` |
| `openGroupOrder` | `Talla Speciality/Features/Commerce/SocialCoffeeView.swift:1145` |
| `homeShortcutCard` | `Talla Speciality/Features/Commerce/ContentView+Home.swift:217` |
| `homePersonalizedProductCard` | `Talla Speciality/Features/Commerce/ContentView+Home.swift:238` |
| `homePersonalizedActionCard` | `Talla Speciality/Features/Commerce/ContentView+Home.swift:267` |
| `fetchAppSettings` | `Talla Speciality/Features/Commerce/CommerceSupport.swift:180` |
| `createCustomerAccessToken` | `Talla Speciality/Features/Commerce/CommerceSupport.swift:429` |
| `createCustomer` | `Talla Speciality/Features/Commerce/CommerceSupport.swift:469` |
| `fetchCustomer` | `Talla Speciality/Features/Commerce/CommerceSupport.swift:510` |
| `uniquedByID` | `Talla Speciality/Features/Commerce/CommerceSupport.swift:2012` |
| `productPreviewDescription` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:325` |
| `recommendationCopy` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:386` |
| `productBrewRecommendation` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:501` |
| `heroStat` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:1208` |
| `infoChip` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:1392` |
| `infoTile` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:1414` |
| `socialChip` | `Talla Speciality/Features/Commerce/ContentView+ProductSupport.swift:1453` |
| `educationCard` | `Talla Speciality/Features/Brewing/CoffeeEducationView.swift:347` |
| `compareMeasuredBrews` | `Talla Speciality/Features/Brewing/CoffeeLibrary.swift:1239` |
| `markBestMeasuredBrew` | `Talla Speciality/Features/Brewing/CoffeeLibrary.swift:1246` |
| `bestMeasuredBrewID` | `Talla Speciality/Features/Brewing/CoffeeLibrary.swift:1250` |
| `shareableBrewCard` | `Talla Speciality/Features/Brewing/CoffeeLibrary.swift:1419` |
| `methodCard` | `Talla Speciality/Features/Brewing/BrewingSectionView+Runtime.swift:112` |
| `methodTag` | `Talla Speciality/Features/Brewing/BrewingSectionView+Runtime.swift:408` |
| `brewModeStepRow` | `Talla Speciality/Features/Brewing/BrewingSectionView+Runtime.swift:1352` |
| `brewingDetail` | `Talla Speciality/Features/Brewing/BrewingSectionView+Runtime.swift:2156` |
| `recipeIconButton` | `Talla Speciality/Features/Brewing/BrewingSectionView+GeneratedRecipe.swift:685` |
| `adjustableRecipeValueCard` | `Talla Speciality/Features/Brewing/BrewingSectionView+GeneratedRecipe.swift:935` |
| `recipeInfoRow` | `Talla Speciality/Features/Brewing/BrewingSectionView+GeneratedRecipe.swift:985` |
| `generatedPourRowView` | `Talla Speciality/Features/Brewing/BrewingSectionView+GeneratedRecipe.swift:1012` |
| `generatedPourStartTime` | `Talla Speciality/Features/Brewing/BrewingSectionView+GeneratedRecipe.swift:1383` |
| `cycleGeneratedGrind` | `Talla Speciality/Features/Brewing/BrewingSectionView+GeneratedRecipe.swift:1417` |
| `continueRecipeDetail` | `Talla Speciality/Features/Brewing/BrewingSectionView+Setup.swift:1462` |
| `applyRecommendedProfileForBrewProfile` | `Talla Speciality/Features/Brewing/BrewingSectionView+Setup.swift:1686` |
| `openMethodCategory` | `Talla Speciality/Features/Brewing/BrewingSectionView+Setup.swift:1753` |
| `improveNextBrew` | `Talla Speciality/Features/Brewing/BrewingSectionView+GuidedCompletion.swift:637` |
| `CoffeeRegionContour` | `Talla Speciality/Features/Discovery/GulfCoffeeMapView.swift:1079` |
| `dashboardStat` | `Talla Speciality/Features/Loyalty/LoyaltyDetailSections.swift:779` |
| `dashboardPreferenceChip` | `Talla Speciality/Features/Loyalty/LoyaltyDetailSections.swift:794` |
| `clubCard` | `Talla Speciality/Features/Loyalty/LoyaltyDetailSections.swift:1027` |
| `refreshSession` | `Talla Speciality/Features/Account/AccountService.swift:385` |
| `createEazyShopifyPaymentSession` | `Talla Speciality/Features/Account/AccountService.swift:1036` |
| `accountWorkspaceCard` | `Talla Speciality/Features/Account/ContentView+AccountViews.swift:644` |
| `workspaceBenefit` | `Talla Speciality/Features/Account/SignedInCustomerSectionView.swift:83` |
| `signedInCountDetail` | `Talla Speciality/Features/Account/SignedInCustomerSectionView.swift:111` |
| `accountCollectionSection` | `Talla Speciality/Features/Account/AccountSectionView.swift:803` |
| `accountCountDetail` | `Talla Speciality/Features/Account/AccountSectionView.swift:825` |
| `LambIconView` | `Talla Speciality/Shared/ContentUIComponents.swift:3` |
| `SummaryValueRow` | `Talla Speciality/Shared/ContentUIComponents.swift:516` |
| `ToastBannerView` | `Talla Speciality/Shared/ContentUIComponents.swift:598` |
| `foundationModelOutput` | `Talla Speciality/Services/Platform/CoffeeConciergeService.swift:728` |
| `isGenericDeflection` | `Talla Speciality/Services/Platform/CoffeeConciergeService.swift:800` |
| `copyPushDeviceToken` | `Talla Speciality/Services/Observability/ContentView+Observability.swift:191` |
| `disableBiometricLogin` | `Talla Admin/AdminSession.swift:177` |

## Validation

### Follow-up — 2026-10-22

- Implemented the account-session generation checks, locale-specific catalog caching, Admin biometric logout reset, test actor-isolation fixes, and reviewed dead-code cleanup described above.
- Corrected the offline recovery banner's accessibility hierarchy so its Retry button remains independently exposed on iOS 27.
- Updated the layout UI tests to target the iOS 27 system bag toolbar item and to scroll the home `ScrollView` directly after rotation.
- Build-for-testing passed with no build errors.
- All eight UI tests listed below passed in focused reruns. The earlier aggregate full-suite action became stuck in Xcode and was not used as evidence of success.

- Xcode active scheme: `Talla Speciality`; build-for-testing passed.
- Backend `npm run verify`: lint and migration validation passed; 194 tests passed, zero failed.
- Apple test run: 130 results, 122 passed, 8 failed, none skipped. Discovery listed 129 tests; the parameterized refresh test produces two result cases. All eight failures are UI tests; see details below.
- The watch unit-test file (`Talla Watch Watch AppTests/Talla_Watch_Watch_AppTests.swift:13`) still contains only the generated empty example test; it provides no behavioral coverage.
- Separate Admin/watch schemes, Android, Release archive, physical Bluetooth scales, real payments, push delivery, and production services were not independently validated.

## Failed Apple UI tests

These are observed failures, not eight independently diagnosed production defects. No rerun or device reproduction was performed. In particular, missing loopback requests may reflect test-server, launch-configuration, or application behavior and require diagnosis.

All locations below are in `Talla SpecialityUITests/Talla_SpecialityUITests.swift`.

| Test | Line | Observed failure |
| --- | --- | --- |
| testCheckoutReachesAuthenticatedOrderAndPaymentServices | 31 | No `/orders/checkout-started` request recorded within 15 seconds after submit. |
| testArabicCheckoutUsesRightToLeftLocalizedContent | 50 | No `/orders/checkout-started` request recorded within 15 seconds. Arabic text assertions passed before this. |
| testAccountDeletionRequiresConfirmationAndClearsIdentity | 66 | No `/accounts/delete` request recorded after confirmation. |
| testAccountTabDoesNotReplayConsumedOrdersRequest | 88 | `more.account` button not found; the final replay assertion was never reached. |
| testOfflineCacheRemainsVisibleAndRetryRecovers | 119 | No `/coffee-data/sync` request recorded after retry. |
| testHomeActionsSurviveRotation | 369 | Home expandable action was not hittable. |
| testNavigationAndSearchSurviveRotation | 416 | Expected tab button not found during navigation after rotation. |
| testOpeningBagDismissesSearchKeyboardAndKeepsItemsVisible | 441 | Keyboard did not appear after tapping search; bag dismissal assertions were never reached. |

Full Xcode test summary: `/var/folders/3x/305f6jhn6lz1qjd1pkgr6lf40000gn/T/ActionArtifacts/43156A33-8511-4703-B100-A5157CEABC06/RunAllTests/6E160778-7F17-42E9-82BB-C5417C3FABA3.txt`.
