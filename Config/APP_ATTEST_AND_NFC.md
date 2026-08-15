# App Attest and NFC rollout

## App Attest

The iOS app registers a hardware-backed App Attest key and signs high-value account, address,
loyalty, voucher, push-registration, checkout, and payment requests. The backend verifies Apple’s
attestation chain, stores the public key, checks one-time challenges, and enforces a monotonically
increasing assertion counter to reject replays.

Deploy the backend with:

```text
APP_ATTEST_APP_ID=TAG9WXY85M.Talla-Speciality.Talla-Speciality
APP_ATTEST_ALLOW_DEVELOPMENT=false
APP_ATTEST_ENFORCE=false
```

Keep enforcement off while the App Store update rolls out so older clients continue to work.
Monitor failed registrations/assertions, then set `APP_ATTEST_ENFORCE=true`. Development
attestations should only be allowed in non-production environments.

## NFC tags

Encode tags as NDEF URI records. Supported destinations are Talla universal links such as:

```text
https://talla.me/products/<shopify-product-handle>
https://talla.me/collections/<shopify-collection-handle>
https://talla.me/app/brewing
https://talla.me/app/rewards
```

The scanner rejects non-Talla domains and hands valid tags to the same navigation path used by
universal links. Test on a physical iPhone; the simulator cannot scan NFC tags or create App Attest
keys.
