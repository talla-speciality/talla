# Talla: the complete coffee companion

## Product promise

Talla should help a customer discover better coffee, buy it with confidence, brew it successfully, remember what worked, and come back for the next cup. Every major surface should connect those jobs instead of behaving like separate features.

## What already exists

- Commerce, Shopify checkout, delivery/pickup, BenefitPay, loyalty, vouchers, saved addresses, and order history.
- Brewing recipes, guided sessions, a brew journal, coffee library, equipment/calibration data, espresso workspace, scale support, and offline sync.
- Coffee Concierge, bag-label scanning, personalized coffee memory, coffee passport, watch app, widgets, education, and admin tools.

## Priority product pillars

### 7. One coherent Talla layer

Talla should combine the strongest competitor patterns into one calm loop rather than expose a collection of separate tools:

| Competitor strength | Talla response |
| --- | --- |
| Filtru’s calm guided brewing | Make Brew Coach the default brewing entry point, with one obvious path into a guided brew. |
| Beanconqueror’s depth | Keep advanced data, history, curves, calibration, and science behind progressive disclosure. |
| Acaia’s scale recipes | Handoff recipe targets to the connected scale profile and show the device-specific live start when available. |
| Brewfather’s versioning and AI | Treat every completed brew and taste signal as input to the next recipe revision, with explainable adjustments. |
| Talla’s advantage | Connect the brew loop directly to local coffee discovery, commerce, loyalty, delivery, and Gulf context. |

The product loop is `Coach → Brew → Taste → Improve → Discover or reorder`. The default surface should feel quiet and useful for a beginner; experts can expand recipe science, equipment, measured curves, and calibration without losing the simple path. A connected device should reduce effort rather than become a prerequisite: when a supported scale is available, the recipe becomes a device-aware live session; when it is not, the same guided session remains fully usable.

Every completed brew should offer one next action: save the feedback, apply a small recipe revision, or discover the next local coffee. Recommendations remain explainable and overridable, and any commerce or Gulf discovery handoff should preserve the coffee, method, and taste context that produced the recommendation.

### Gulf Coffee Map moat

The Gulf Coffee Map should be treated as Talla’s regional knowledge layer, not a directory screen. Every listing becomes a maintained coffee profile with a visible trust state, Arabic and English identity, city context, current offerings, verified tasting notes, brew guidance, and an events surface.

The defensibility comes from the loop: Talla verifies a place or roaster, customers log a visit and taste, baristas and partners add structured sensory context, and the resulting regional coffee graph improves city recommendations and “brew this coffee at home” guidance. Ratings alone are easy to copy; verified provenance, local language, repeat tasting history, and partner-maintained freshness are not.

The first product slice should connect:

- verified profiles and link/manual verification states;
- a regional coffee passport tied to visited places and coffees tried;
- structured tasting notes with moderation and provenance;
- a recipe handoff from any bean or drink to a home-brew guide;
- city picks, cuppings, workshops, and local events;
- Arabic-first discovery copy with English parity.

The backend should make profile freshness explicit (`verifiedAt`, `verifiedBy`, `lastCheckedAt`, and `sourceURL`), keep public notes separate from private memory, and record explainable recommendation signals. The operating metric is not map views; it is verified discovery that becomes a saved taste memory, a completed brew, a repeat visit, or a Talla reorder.

The admin workspace owns the maintenance loop: editors can update trust and freshness fields, bilingual profile copy, tasting notes, offerings, brew guidance, and local events from the Gulf Coffee Map directory editor. This keeps the moat alive as places, menus, and event calendars change.

Published events are now part of the same profile graph, allowing a place to surface its next cupping or workshop in context instead of sending customers to a disconnected calendar.

### 1. Discover and choose

- Taste quiz that recommends a coffee, brew method, grind, and starter recipe.
- Product pages that show origin, producer, process, roast level, tasting notes, freshness, recommended recipes, and “buy the setup” bundles.
- Scan a bag to add it to the coffee library, open its recommended recipe, and reorder it later.
- Search by taste, method, occasion, caffeine preference, budget, and availability.

### 2. Buy without friction

- Fast checkout with delivery versus Riffa pickup clearly separated.
- Prepaid Coffee Club plans with flexible pause, skip, swap, cancellation, and scheduled reorders based on estimated consumption. True automatic renewal is intentionally deferred until vaulted payment methods and renewal failure handling are production-ready.
- Gift flows, bundles, waitlists, back-in-stock alerts, and order tracking.
- Loyalty wallet with points, tiers, rewards, referrals, and Apple Wallet continuity.

### 3. Brew with confidence

- Method-specific guided timers with voice/haptics, step-by-step pours, and live scale integration.
- Smart recipe scaling for dose, water, ratio, yield, and servings.
- Troubleshooting that turns taste feedback into the next adjustment.
- Espresso dialing-in with shot timer, dose/yield, pressure/temperature samples, and grinder notes.
- Equipment profiles, maintenance reminders, and calibration history.

### 4. Learn and build taste

- Structured learning path from coffee basics to advanced extraction.
- Interactive flavour wheel, cupping mode, origin/processing lessons, and short quizzes.
- Arabic and English content parity, captions, accessible text, and downloadable guides.
- Events, workshops, barista tips, and community recipe sharing with moderation.

### 5. Remember and personalize

- Coffee passport for origins, coffees tried, recipes, ratings, and tasting notes.
- “Brew again” and “make it better” actions on every completed session.
- Personal taste profile that improves recommendations without hiding user controls.
- Household profiles for shared equipment and separate preferences.

## Customer journey to design around

`Discover → Choose → Buy → Prepare → Brew → Taste → Save → Improve → Reorder`

Each completed step should offer exactly one obvious next action. For example, a finished brew should lead to rating, a suggested adjustment, and reorder—not a dead end.

## Recommended delivery sequence

### Release 1: connect what exists

1. Make product, bag scan, coffee library, recipe, brew session, rating, and reorder one connected flow.
2. Add “recommended recipe” and “brew this coffee” CTAs to product and library views.
3. Persist education progress and taste profile instead of keeping it only in view state.
4. Add a first-run setup that asks for method, equipment, taste preference, and skill level.
5. Audit Arabic localization, accessibility identifiers, empty states, loading states, and offline behavior.

### Release 2: retention and convenience

1. Add subscriptions, reorder reminders, back-in-stock alerts, and brew-day notifications.
2. Add maintenance schedules and a household equipment profile.
3. Add richer order tracking and pickup readiness notifications.
4. Add referral rewards, gifting, and curated bundles.

### Release 3: expert companion

1. Add live guided brew sessions with voice/haptics and scale events.
2. Add espresso dialing-in history and shot comparison.
3. Add cupping mode, sensory calibration, events, and moderated community recipes.
4. Add privacy controls and transparent recommendation explanations.

## Success measures

- First brew completed within 10 minutes of install.
- Recommendation-to-product conversion.
- Purchase-to-first-brew completion.
- Brew journal rating completion and repeat-brew rate.
- 30-day reorder/subscription retention.
- Education lesson completion and improvement in brew ratings.
- Checkout success, pickup readiness, support contacts, and crash-free sessions.

## Non-negotiables

- Never expose payment or admin secrets in clients.
- Keep feature code in its owning module; preserve the documented composition-root budgets.
- Treat offline data, sync conflicts, deletion, accessibility, Arabic localization, and privacy as first-class product behavior.
- Recommendations must be explainable and overridable by the customer.
