# Talla Speciality

The Talla monorepo contains the native Apple clients, native Android client, and shared Node/Postgres backend.

## Projects

- `Talla Speciality/`, `Talla Watch Watch App/`, and the Xcode project: iOS, widgets, and watchOS.
- `android/`: Kotlin and Jetpack Compose Android app. Open this directory directly in Android Studio.
- `backend/`: shared account, commerce, loyalty, notification, and payment service used by both mobile apps.

The mobile clients share the production backend at `https://talla-backend.onrender.com`. Payment-provider secrets remain in Render and must never be committed to either client.

### Android verification

```bash
cd android
./gradlew test assembleDebug lintDebug
```

Authorized vendor payment SDKs are installed locally according to `android/README.md` and are intentionally excluded from Git.

## Delivery rates

The iOS bag calculates delivery from the preferred address and Shopify variant weights:

- Bahrain: BHD 2.000.
- Saudi Arabia, Kuwait, UAE, Qatar, and Oman: BHD 5.500 up to 0.5 kg; BHD 6.500 up to 1 kg; BHD 7.500 up to 1.5 kg; BHD 8.500 up to 2 kg; BHD 9.500 up to 2.5 kg; BHD 10.500 up to 3 kg; BHD 11.500 up to 3.5 kg; and BHD 12.500 up to 4 kg.
- Khaleeji transit time: 3 to 5 business days.
- Cash on delivery adds BHD 2.000 for the five Khaleeji destinations above.
- Khaleeji checkout is stopped when a physical Shopify variant has no weight or the shipment exceeds 4 kg.
- Customers can save addresses for all international countries. Destinations outside the GCC continue through Shopify Checkout, where Shopify calculates the configured international shipping rate and shows the payment methods available for that country.

Every physical Shopify variant must have its shipping weight populated. Cash on delivery opens Shopify Checkout, so its Shopify shipping profiles and any COD-fee customization must use the same rates to keep the final checkout amount aligned with the app.

Customers can choose free pickup from Talla in Riffa instead of delivery. Pickup orders do not require a saved delivery address, are labeled as pickup orders for operations, and include a `talla_fulfillment_method=pickup` Shopify cart attribute. Shopify local pickup must be enabled for the Talla location so Shopify-hosted cash checkout offers the same choice.
