# Backend Deployment

This backend is ready to be deployed as a small HTTP API behind a public HTTPS domain such as `https://api.tallaspeciality.com`.

## Recommended first deployment

Use a simple container host:

- Railway
- Render
- Fly.io
- DigitalOcean App Platform

All four can run this service from the included `Dockerfile`.

## Required production setup

Set these environment variables in your host:

```text
HOST=0.0.0.0
PORT=8787
NODE_ENV=production
APP_URL=https://api.tallaspeciality.com
CORS_ALLOWED_ORIGIN=*
DATA_DIRECTORY=/data
DATABASE_URL=postgres://...
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change-me
ADMIN_SESSION_SECRET=replace-with-a-random-secret
ADMIN_SESSION_HOURS=12
CUSTOMER_TOKEN_SECRET=replace-with-a-different-random-secret
CUSTOMER_TOKEN_HOURS=168
RESEND_API_KEY=re_xxx
EMAIL_FROM_ADDRESS=Talla Speciality <no-reply@your-domain.com>
PASSWORD_RESET_TOKEN_HOURS=1
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=240
REQUEST_LOGGING_ENABLED=true
OPS_ALERT_WEBHOOK_URL=
OPS_ALERT_CHECK_INTERVAL_MS=300000
OPS_ALERT_WINDOW_MINUTES=15
OPS_ALERT_5XX_THRESHOLD=5
OPS_ALERT_429_THRESHOLD=20
OPS_ALERT_COOLDOWN_MINUTES=30
SHOPIFY_ADMIN_SHOP_DOMAIN=your-store.myshopify.com
SHOPIFY_ADMIN_ACCESS_TOKEN=shpat_...
SHOPIFY_ADMIN_API_VERSION=2025-10
SHOPIFY_ADMIN_PUBLICATION_ID=gid://shopify/Publication/...
SHOPIFY_WEBHOOK_SECRET=replace-with-shopify-webhook-secret
EAZY_APP_ID=
EAZY_SECRET_KEY=
EAZY_API_BASE_URL=https://api.eazy.net
EAZY_PAYMENT_METHODS=BENEFITGATEWAY,CREDITCARD,APPLEPAY
BENEFIT_TRANPORTAL_ID=
BENEFIT_TRANPORTAL_PASSWORD=
BENEFIT_RESOURCE_KEY=
BENEFIT_API_ENDPOINT=https://www.benefit-gateway.bh/payment/API/hosted.htm
BENEFIT_SUCCESS_URL=https://talla-backend.onrender.com/api/payments/benefit/result
BENEFIT_ERROR_URL=https://talla-backend.onrender.com/api/payments/benefit/result
BENEFIT_NOTIFICATION_URL=https://talla-backend.onrender.com/api/payments/benefit/response
BENEFITPAY_APP_ID=
BENEFITPAY_MERCHANT_ID=
BENEFITPAY_SECRET_KEY=
BENEFITPAY_CHECK_STATUS_URL=
BENEFITPAY_MERCHANT_NAME=
BENEFITPAY_MERCHANT_CITY=
BENEFITPAY_MCC=
BENEFITPAY_COUNTRY_CODE=BH
MPGS_MERCHANT_ID=
MPGS_API_PASSWORD=
MPGS_API_VERSION=100
MPGS_BASE_URL=https://eazypay.gateway.mastercard.com
WALLET_PASS_TEMPLATE_DIRECTORY=/app/WalletPass/TallaLoyalty.pass
WALLET_P12_PATH=/run/secrets/talla-wallet.p12
WALLET_P12_BASE64=
WALLET_P12_PASSWORD=your-password
WALLET_WWDR_PATH=/run/secrets/AppleWWDRCAG4.cer
WALLET_WWDR_BASE64=
```

Notes:

- `HOST` should stay `0.0.0.0` in containers
- `NODE_ENV` must be `production` so App Attest and APNs use secure production defaults
- `APP_URL` should be your real public URL
- `DATA_DIRECTORY` should be backed by persistent storage, not ephemeral container disk
- `DATABASE_URL` should point to your managed Postgres instance
- `ADMIN_USERNAME`, `ADMIN_PASSWORD`, and `ADMIN_SESSION_SECRET` power the admin login and signed session cookie
- `CUSTOMER_TOKEN_SECRET` enables customer session issuance; set it explicitly in production
- `RESEND_API_KEY` and `EMAIL_FROM_ADDRESS` enable customer password reset emails
- `PASSWORD_RESET_TOKEN_HOURS` controls how long each emailed reset link stays valid
- `RATE_LIMIT_WINDOW_MS` and `RATE_LIMIT_MAX_REQUESTS` control per-IP request throttling
- `REQUEST_LOGGING_ENABLED=true` records request logs in Postgres for audit and debugging
- `OPS_ALERT_WEBHOOK_URL` enables automated webhook alerts from `request_logs`
- `OPS_ALERT_5XX_THRESHOLD` and `OPS_ALERT_429_THRESHOLD` control when alerts fire
- `OPS_ALERT_COOLDOWN_MINUTES` limits duplicate alerts for the same issue type
- `SHOPIFY_ADMIN_SHOP_DOMAIN` and `SHOPIFY_ADMIN_ACCESS_TOKEN` enable live product control from `/admin`
- `SHOPIFY_ADMIN_PUBLICATION_ID` is optional, but without it newly created products may not appear in the storefront-backed iOS app
- `SHOPIFY_WEBHOOK_SECRET` verifies Shopify `orders/create` webhooks before any order or payment state is stored
- `EAZY_APP_ID` and `EAZY_SECRET_KEY` are required for EazyPay invoice creation and Query API verification; keep both in Render secrets
- `EAZY_API_BASE_URL` defaults to `https://api.eazy.net`; use an EazyPay-provided sandbox URL during UAT
- `EAZY_PAYMENT_METHODS` defaults to `BENEFITGATEWAY,CREDITCARD,APPLEPAY`
- All seven `BENEFIT_*` variables are required for hosted checkout; keep the merchant credentials and resource key in Render secrets. Production uses `https://www.benefit-gateway.bh/payment/API/hosted.htm`.
- `BENEFIT_SUCCESS_URL` and `BENEFIT_ERROR_URL` should use `/api/payments/benefit/result`, while `BENEFIT_NOTIFICATION_URL` should use `/api/payments/benefit/response`
- BenefitPay is a separate in-app SDK flow. Keep all `BENEFITPAY_*` values supplied for production in Render, and set `BENEFITPAY_CHECK_STATUS_URL` to the exact production check-status URL supplied by BenefitPay.
- The iOS BenefitPay SDK secret belongs in the ignored `Config/BenefitPaySecrets.xcconfig` file as `BENEFITPAY_SDK_SECRET_KEY = ...`; never commit that file. The production SDK archive supplied by BenefitPay matches the framework already stored under `Vendor/BenefitPay`.
- The KeyStore files and alias name are only for plugin integration and are not used by Talla's API integration.
- `MPGS_MERCHANT_ID` and `MPGS_API_PASSWORD` are required for card sessions; keep the API password in Render secrets
- `MPGS_API_VERSION` defaults to `100`, and `MPGS_BASE_URL` defaults to the EazyPay Mastercard Gateway host
- Wallet pass signing requires both the signer `.p12` and the WWDR certificate; on Render, a base64 signer cert plus a repo-tracked WWDR file is the most stable setup
- `/admin` now includes an operations snapshot powered by `request_logs`

## EazyPay manual-payment setup

The EazyPay flow keeps Shopify as the source of truth for the order total. The iOS app creates a Shopify cart with an opaque `talla_payment_id`, then the customer selects the exact manual payment method name `Pay with EazyPay` in Shopify Checkout.

Configure Shopify:

1. In **Settings → Payments → Manual payment methods**, add a custom method named exactly `Pay with EazyPay`.
2. Configure an `orders/create` webhook to `https://talla-backend.onrender.com/webhooks/shopify/orders-create`.
3. Set the same webhook signing secret as `SHOPIFY_WEBHOOK_SECRET` in Render.
4. Give the Admin API custom app `write_orders` access and permission to mark orders paid.

Configure EazyPay:

1. Set the four `EAZY_*` variables above in Render.
2. Configure EazyPay notifications to `https://talla-backend.onrender.com/webhooks/eazypay`.
3. Ask EazyPay for its webhook signature or authentication specification before production launch. The backend currently treats notifications only as triggers and independently verifies payment using EazyPay's Query API.

Runtime flow:

1. The authenticated app registers a `talla_payment_id` with `POST /api/payments/eazy/shopify/session`.
2. Shopify sends the signed order webhook containing that ID and its trusted BHD total.
3. The backend creates one EazyPay invoice and stores the hosted payment URL.
4. The app polls `GET /api/payments/eazy/shopify/status?tallaPaymentId=...` and opens that URL.
5. An EazyPay notification triggers Query API verification; the redirect or notification status is never accepted as proof of payment.
6. After invoice, currency, and amount checks pass, the backend calls Shopify Admin GraphQL `orderMarkAsPaid` and applies local fulfilment and loyalty effects idempotently.

Before production, confirm with EazyPay:

- the official webhook signature header and canonical signing payload
- the UAT and production API base URLs and credentials
- whether `createInvoice` is idempotent when the same `invoiceId` is retried
- the exact webhook transaction-ID field names and content types
- supported return/cancel URL fields and merchant metadata

## Build and run locally with Docker

From the repo root:

```bash
docker build -f backend/Dockerfile -t talla-backend .
docker run --rm -p 8787:8787 \
  -e HOST=0.0.0.0 \
  -e PORT=8787 \
  -e APP_URL=http://localhost:8787 \
  -e DATA_DIRECTORY=/app/data \
  talla-backend
```

Then check:

```bash
curl http://localhost:8787/health
```

## DNS and TLS

1. Create a subdomain such as `api.tallaspeciality.com`
2. Point DNS to your hosting provider
3. Enable HTTPS/TLS at the platform or reverse proxy
4. Confirm `GET /health` returns `200`

## iOS app integration

After deployment, set `BackendBaseURL` in the app’s `Info.plist` to:

```text
https://api.tallaspeciality.com
```

Do not use `127.0.0.1`, `localhost`, or a private LAN IP for production users.

## Shopify app-order mirroring

After a Talla payment is confirmed and the local order becomes completed, the backend creates one matching Shopify order. It sends only the customer email, preferred delivery phone number, Shopify variant IDs, quantities, currency, and a generic Talla app tag/note. Payment gateway names, credentials, transaction IDs, and payment payloads are not sent.

The existing Shopify Admin token must include `write_orders`. Mirrored orders are intentionally created as `PENDING`, with receipts disabled and inventory behavior set to `BYPASS`, because Shopify is receiving an administrative copy rather than confirming or processing the payment.

## Backups and restore

Your current durable data lives in Postgres, so backups should target the database directly.

### Backup

From your Mac, use the Render external database URL:

```bash
pg_dump "YOUR_RENDER_EXTERNAL_DATABASE_URL" --format=custom --file=talla-backup.dump
```

Optional plain SQL export:

```bash
pg_dump "YOUR_RENDER_EXTERNAL_DATABASE_URL" --file=talla-backup.sql
```

### Restore

Restore a custom dump:

```bash
pg_restore --clean --if-exists --no-owner --no-privileges \
  --dbname="YOUR_RENDER_EXTERNAL_DATABASE_URL" \
  talla-backup.dump
```

Restore a plain SQL dump:

```bash
psql "YOUR_RENDER_EXTERNAL_DATABASE_URL" < talla-backup.sql
```

### Practical policy

1. Take a backup before backend auth, wallet, or schema changes.
2. Keep one recent local backup and one off-machine backup.
3. Test restore into a separate Postgres database, not production.
4. Only run `pg_restore --clean` against production if you explicitly want to replace live data.

## Database migrations

The backend now uses versioned SQL migrations in `backend/migrations`.

Manual migration command:

```bash
cd backend
npm run migrate
```

Current behavior:

- pending migrations are applied automatically on backend startup
- `schema_migrations` tracks which SQL files have already run
- future schema changes should go into a new numbered `.sql` file, not inline startup SQL

## Automated ops alerts

If you want the backend to push alerts automatically, set:

```text
OPS_ALERT_WEBHOOK_URL=https://your-webhook-endpoint
OPS_ALERT_CHECK_INTERVAL_MS=300000
OPS_ALERT_WINDOW_MINUTES=15
OPS_ALERT_5XX_THRESHOLD=5
OPS_ALERT_429_THRESHOLD=20
OPS_ALERT_COOLDOWN_MINUTES=30
```

This monitor runs inside the backend process and uses `request_logs` to detect elevated 5xx or 429 activity.

## Important production gaps

This backend is deployable, but not yet production-hardened. Before public launch, you should add:

- refresh token flow instead of a single long-lived customer session token
- stronger admin authentication and authorization than HTTP Basic Auth
- immutable audit review workflow for sensitive admin actions
- operational monitoring on top of the request logs
- rate limiting
- secret management for Wallet signing assets
- automated backups for Postgres
