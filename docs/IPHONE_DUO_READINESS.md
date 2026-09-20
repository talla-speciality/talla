# iPhone Duo layout update

## Scope

Build with Xcode 27.1 and the iOS 27.1 SDK. The deployment target stays at iOS 17; the new system-toolbar and reserved-region behavior is availability guarded.

- Use a stable sidebar-adaptable TabView across size-class changes; preserve tab content identity and local state.
- Put each tab in a NavigationStack so the system can place navigation actions in Duo’s vertical bar. Bag has a count badge; appearance and language remain accessible in the toolbar. Older systems retain the original header actions.
- Scroll branding with the page on 27.1 to free vertical content space.
- Expand the content bounds for the inner display and wider compact windows while retaining safe-area layout.
- Give Home a larger typographic hierarchy, warm branded hero, optional artwork column, 48-point primary actions, and paired roast cards.
- Measure the hero’s own container rather than the screen. Read active division regions to keep the hero text and actions on the leading side of a vertical fold; region coordinates use SwiftUI’s default layout-direction mirroring. Decorative artwork disappears at narrow widths and accessibility text sizes. The main feed remains a continuous scroll view.

## Validation on September 20, 2026

The iOS 27.1 simulator app and UI test bundle compiled and linked. `git diff --check` passed.

Added `TallaDeviceLayoutTests.testHomeActionsSurviveRotation`, checking action reachability, minimum target height, window containment, and navigation into Shop. Also attempted the existing navigation/search rotation test.

Both test attempts were blocked before the runner launched: the first simulator shut down during setup; the second connected to testmanagerd but stalled while initiating the session. Device Hub accessibility inspection also timed out. These are not passing UI test results. No rendered-screen or fold-pose verification is claimed.

## Remaining device checks

Run the focused tests on a functioning Duo simulator, then inspect open/closed transitions, book and tabletop poses, Split View, Arabic, accessibility text sizes, light/dark/OLED appearance, cart access, and each tab. Confirm the hero clears the active fold and system controls avoid both cameras. Also smoke-test a standard iPhone and iPad on an older supported runtime.

Reference: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
