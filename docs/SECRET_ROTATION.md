# Production secret rotation policy

Production credentials are stored only in Render, GitHub Actions secrets, Apple/Google consoles, and the payment-provider portals. They must never be committed, copied into tickets, or posted in chat.

## Cadence

| Secret | Rotation | Owner | Rollout |
| --- | --- | --- | --- |
| Postgres password and external URL | 90 days | Backend owner | Rotate in Render, update GitHub backup secret, deploy, then revoke the old credential. |
| Admin users, passwords, and session HMAC | 90 days and immediately after staff changes | Operations owner | Update `ADMIN_USERS_JSON`; rotate `ADMIN_SESSION_SECRET` after the user change to invalidate old sessions. |
| Customer session configuration | 180 days | Backend owner | Access tokens last one hour and refresh tokens rotate on every use. A refresh-token reuse event revokes its whole token family. |
| Shopify, Resend, VAPID, Google, APNs, Wallet, BENEFIT, BenefitPay, EazyPay, and MPGS credentials | 90 days or provider minimum | Named integration owner | Create the replacement, deploy and verify it, then revoke the old value. Use the provider's overlap window where supported. |
| Backup encryption key | 90 days | Security owner | Retain old keys until every backup encrypted by them has expired. |

## Required procedure

1. Create a tracked rotation change with an owner and expiry date; never include the value.
2. Create the replacement credential in the provider and record its last four characters in the audit note.
3. Update the protected environment, deploy, and run the external health check plus the affected payment/authentication smoke test.
4. Revoke the old credential only after verification. If compromise is suspected, revoke first and accept the controlled outage.
5. Confirm logs, crash reports, telemetry, and GitHub output contain no secret value.
6. Record completion and the next rotation date.

Any credential pasted into chat, source control, CI logs, screenshots, or an unencrypted file is considered compromised and must be rotated immediately.
