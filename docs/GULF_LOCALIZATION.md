# Gulf localization

New installations start in Arabic; customers can select English or system language. The iOS root applies the matching locale and layout direction. The Arabic checkout was visually inspected in the iPhone simulator; Android visual QA remains outstanding because this machine has no Java runtime.

GCC address data is stored separately from the street line: region, district, block, building, unit, postal code, Saudi additional number, and landmark. Existing records without structured details remain readable. iOS passes region, postal code and delivery details into the Shopify checkout address; country-aware required fields are enforced on both address forms.

Pricing and checkout behavior have been restored to their previous implementation at the customer's request. The iOS app shows the existing local-currency conversion for the preferred address, native gateways continue charging BHD, and the original payment choices and Shopify checkout behavior are retained.

The web admin's fulfillment controls accept `gulfMarkets`, keyed by ISO country code. Each entry has `verified`, `deliveryEN`, `deliveryAR`, `heatSafePackaging`, `packagingEN`, and `packagingAR`. A market is treated as verified only when both delivery-language fields are populated; heat-safe packaging additionally requires both packing-instruction fields. The admin rejects incomplete verified claims, and server normalization suppresses them as a second safety gate. Set delivery copy after confirming carrier transit, dispatch cutoffs, non-working days and remote-area exclusions. Include those qualifications in both languages. Both apps show a confirmation fallback when no verified policy exists.

The merchant has confirmed the heat-safe packaging for GCC orders. The configured packing instruction is to use the heat-safe materials for every order. The software exposes merchant-verified operational information; it does not independently certify packaging or change the physical packing process.

Verified native delivery orders copy the packaging requirement into fulfillment notes for the order queue. Shopify-hosted orders require matching Shopify packing workflows; configure them before enabling a packaging claim for those destinations.

KNET, STC Pay and Tabby remain outside this change. Both checkouts expose the configured WhatsApp support link. Arabic coffee and gahwa are named as a first-class category; Android recognition includes gahwa/qahwa terms. Remaining app-translation gaps found in keyed copy were filled.

Merchant-provided delivery promises are configured: Bahrain is same-day, with night orders delivered the following morning; Saudi Arabia, Kuwait, the UAE, Qatar and Oman are within three days. Confirm the dispatch process continues to meet these promises. Shopify packing workflows still need to be configured to use the same heat-safe materials for Shopify-fulfilled destinations.
