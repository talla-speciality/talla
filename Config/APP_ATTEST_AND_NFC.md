# App Attest rollout

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

Test App Attest on a physical iPhone or iPad; the simulator cannot create App Attest keys.
