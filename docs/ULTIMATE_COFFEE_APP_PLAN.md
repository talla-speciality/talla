# Talla: the complete coffee companion

## Product promise

Talla should help a customer discover better coffee, buy it with confidence, brew it successfully, remember what worked, and come back for the next cup. Every major surface should connect those jobs instead of behaving like separate features.

## What already exists

- Commerce, Shopify checkout, delivery/pickup, BenefitPay, loyalty, vouchers, saved addresses, and order history.
- Brewing recipes, guided sessions, a brew journal, coffee library, equipment/calibration data, espresso workspace, scale support, and offline sync.
- Coffee Concierge, bag-label scanning, personalized coffee memory, coffee passport, watch app, widgets, education, and admin tools.

## Priority product pillars

### 1. Discover and choose

- Taste quiz that recommends a coffee, brew method, grind, and starter recipe.
- Product pages that show origin, producer, process, roast level, tasting notes, freshness, recommended recipes, and “buy the setup” bundles.
- Scan a bag to add it to the coffee library, open its recommended recipe, and reorder it later.
- Search by taste, method, occasion, caffeine preference, budget, and availability.

### 2. Buy without friction

- Fast checkout with delivery versus Riffa pickup clearly separated.
- Subscriptions and scheduled reorders based on estimated consumption.
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
