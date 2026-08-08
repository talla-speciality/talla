# Talla Backend

Backend API for the Talla Speciality iOS app. This service currently backs:

- customer accounts
- loyalty balances and transactions
- sample orders
- stock alerts and alert inbox
- saved addresses
- vouchers
- Wallet pass download
- admin customer lookup and loyalty adjustments
- Shopify product management from the admin console

## Run

```bash
cd backend
npm start
```

By default the service listens on `0.0.0.0:8787`.

For local development on your Mac:

```bash
cd backend
cp .env.example .env
HOST=0.0.0.0 PORT=8787 npm start
```

For production, set environment variables in your host platform and expose the API over HTTPS behind a real domain such as `https://api.tallaspeciality.com`.

See [DEPLOYMENT.md](./DEPLOYMENT.md) for the public-host deployment path.

## Configuration

The server reads configuration from environment variables:

- `HOST`: bind address, defaults to `0.0.0.0`
- `PORT`: listener port, defaults to `8787`
- `APP_URL`: public URL used in logs and health output
- `CORS_ALLOWED_ORIGIN`: CORS origin, defaults to `*`
- `DATA_DIRECTORY`: JSON data storage directory
- `DATABASE_URL`: optional Postgres connection string for accounts, loyalty, wallet pass metadata, addresses, vouchers, orders, stock alerts, and alert inbox
- `ADMIN_USERNAME`: admin username for `/admin`
- `ADMIN_PASSWORD`: admin password for `/admin`
- `ADMIN_SESSION_SECRET`: secret used to sign admin session cookies
- `ADMIN_SESSION_HOURS`: admin session lifetime in hours, defaults to `12`
- `CUSTOMER_TOKEN_SECRET`: secret required to enable customer session issuance
- `CUSTOMER_TOKEN_HOURS`: customer session lifetime in hours, defaults to `168`
- `RESEND_API_KEY`: Resend API key used for customer password reset emails
- `EMAIL_FROM_ADDRESS`: verified sender for password reset emails, such as `Talla Speciality <no-reply@your-domain.com>`
- `PASSWORD_RESET_TOKEN_HOURS`: password reset link lifetime in hours, defaults to `1`
- `RATE_LIMIT_WINDOW_MS`: rate limit window in milliseconds, defaults to `60000`
- `RATE_LIMIT_MAX_REQUESTS`: max requests per IP and path within the window, defaults to `240`
- `REQUEST_LOGGING_ENABLED`: writes request logs to Postgres when `true`
- `OPS_ALERT_WEBHOOK_URL`: optional webhook target for automated operational alerts
- `OPS_ALERT_CHECK_INTERVAL_MS`: how often the backend checks alert thresholds, defaults to `300000`
- `OPS_ALERT_WINDOW_MINUTES`: rolling request-log window size for alert checks, defaults to `15`
- `OPS_ALERT_5XX_THRESHOLD`: send an alert when 5xx responses in the window reach this count, defaults to `5`
- `OPS_ALERT_429_THRESHOLD`: send an alert when 429 responses in the window reach this count, defaults to `20`
- `OPS_ALERT_COOLDOWN_MINUTES`: minimum delay before the same alert type can fire again, defaults to `30`
- `SHOPIFY_ADMIN_SHOP_DOMAIN`: shop domain for Shopify Admin GraphQL, such as `your-store.myshopify.com`
- `SHOPIFY_ADMIN_ACCESS_TOKEN`: custom app Admin API access token with product scopes
- `SHOPIFY_ADMIN_API_VERSION`: Shopify Admin GraphQL version, defaults to `2025-10`
- `SHOPIFY_ADMIN_PUBLICATION_ID`: optional publication ID used to publish newly created products to the storefront
- `SHOPIFY_WEBHOOK_SECRET`: secret used to verify Shopify webhook HMAC signatures
- `EAZY_APP_ID`: EazyPay checkout application ID
- `EAZY_SECRET_KEY`: EazyPay HMAC secret; never expose it to a client or logs
- `EAZY_API_BASE_URL`: EazyPay API origin, defaults to `https://api.eazy.net`
- `EAZY_PAYMENT_METHODS`: comma-separated hosted methods, defaults to `BENEFITGATEWAY,CREDITCARD,APPLEPAY`
- `BENEFIT_TRANPORTAL_ID`: BENEFIT merchant transportal ID
- `BENEFIT_TRANPORTAL_PASSWORD`: BENEFIT merchant transportal password
- `BENEFIT_RESOURCE_KEY`: BENEFIT AES resource key
- `BENEFIT_API_ENDPOINT`: BENEFIT hosted-payment API endpoint
- `BENEFIT_SUCCESS_URL`: public HTTPS result-page URL used after an approved payment
- `BENEFIT_ERROR_URL`: public HTTPS result-page URL used after a failed payment
- `BENEFIT_NOTIFICATION_URL`: public HTTPS notification URL ending in `/api/payments/benefit/response`
- `MPGS_MERCHANT_ID`: Mastercard Gateway merchant ID
- `MPGS_API_PASSWORD`: Mastercard Gateway API password; never expose it to clients
- `MPGS_API_VERSION`: Mastercard Gateway REST API version, defaults to `100`
- `MPGS_BASE_URL`: Mastercard Gateway origin, defaults to `https://eazypay.gateway.mastercard.com`
- `WALLET_PASS_TEMPLATE_DIRECTORY`: Wallet pass template directory
- `WALLET_P12_PATH`: signing certificate path for Wallet passes
- `WALLET_P12_BASE64`: base64-encoded `.p12` certificate content for hosted environments
- `WALLET_P12_PASSWORD`: signing certificate password
- `WALLET_WWDR_PATH`: Apple WWDR certificate path
- `WALLET_WWDR_BASE64`: base64-encoded WWDR certificate content for hosted environments

## Admin

The backend serves a lightweight admin console at:

```text
/admin
```

It uses a login form backed by a signed admin session cookie. Configure it with `ADMIN_USERNAME`, `ADMIN_PASSWORD`, and `ADMIN_SESSION_SECRET`.

Current admin capabilities:

- customer lookup by email
- loyalty balance inspection
- manual loyalty point adjustments
- visibility into orders, addresses, vouchers, stock alerts, and inbox records
- audit trail for admin loyalty adjustments
- logout support and cookie-based admin sessions
- rate limiting and request logging on the shared backend
- operations snapshot for recent traffic, 5xx responses, and rate-limit activity
- Shopify product add, update, and delete controls
- automated webhook alerts for elevated 5xx or 429 volume

## Seed Account

Use this email in the app to test the lookup flow:

```text
guest@talla.example
```

## Endpoints

### Health

```http
GET /health
```

Example response:

```json
{
  "status": "ok",
  "appURL": "https://api.tallaspeciality.com",
  "host": "0.0.0.0",
  "port": 8787
}
```

### BENEFIT hosted checkout

```http
POST /api/payments/benefit/create
POST /api/payments/benefit/response
GET  /api/payments/benefit/result
```

The create route requires an authenticated customer and an existing order ID. The backend derives the BHD amount from the stored order, encrypts the hosted-payment request, and returns the BENEFIT payment URL. The public response route validates the decrypted notification against the pending payment before applying payment effects idempotently. The result page reads backend state only.

### EazyPay through Shopify manual payment

```http
POST /api/payments/eazy/shopify/session
GET  /api/payments/eazy/shopify/status?tallaPaymentId=TL-...
POST /webhooks/shopify/orders-create
POST /webhooks/eazypay
```

The app registers an opaque payment ID, attaches it to a Shopify Storefront cart, and asks the customer to select the exact Shopify manual method `Pay with EazyPay`. The signed Shopify order webhook supplies the trusted BHD total. EazyPay notifications are notification-only: the backend confirms the transaction with EazyPay's Query API, checks invoice, amount, and currency, then marks the Shopify order paid through Admin GraphQL. Repeated webhooks and polling requests reuse durable payment state so Shopify marking, fulfilment, and loyalty effects run only once.

### Mastercard Gateway card sessions

```http
POST /api/payments/card/session
POST /api/payments/card/session/retrieve
POST /api/payments/card/authentication/initiate
POST /api/payments/card/authentication/complete
POST /api/payments/card/order/retrieve
POST /api/payments/card/complete
POST /api/payments/apple-pay/session
POST /payments/apple-pay/authorize
POST /api/payments/click-to-pay/create
GET  /api/payments/click-to-pay/launch
GET  /api/payments/click-to-pay/return
```

Authenticated MPGS routes enforce order ownership and derive BHD totals from backend order storage. Card payments use 3DS2 authentication followed by PAY and gateway-order retrieval. Apple Pay accepts only an SDK-created session ID, never a payment token. Click to Pay uses Hosted Checkout with `INITIATE_CHECKOUT` and verifies the gateway order after return. Confirmed effects are applied idempotently.

`Gateway.xcframework` and `uSDK.xcframework` are required before the native card-entry, 3DS challenge, and Apple Pay SDK handoffs can be enabled in the iOS app. They are intentionally not vendored or imitated by this repository.

### Customer session

```http
GET /accounts/session
Authorization: Bearer <access-token>
```

### Customer login

```http
POST /accounts/login
Content-Type: application/json
```

Response shape:

```json
{
  "profile": {
    "id": "acct_123",
    "firstName": "Ahmad",
    "lastName": "Alweswasi",
    "email": "guest@talla.example"
  },
  "accessToken": "signed-token",
  "expiresAt": "2026-01-01T00:00:00.000Z"
}
```

### Request password reset email

```http
POST /accounts/password/request-reset
Content-Type: application/json
```

```json
{
  "email": "guest@talla.example"
}
```

This sends a hosted reset link by email when `RESEND_API_KEY` and `EMAIL_FROM_ADDRESS` are configured.

### Lookup loyalty account

```http
GET /loyalty/account?email=guest@talla.example
```

### Upsert loyalty account

```http
POST /loyalty/account
Content-Type: application/json
```

```json
{
  "email": "guest@talla.example",
  "memberID": "TALLA-1001",
  "pointsBalance": 245,
  "tier": "Gold",
  "nextReward": "55 points to your next reward",
  "perks": [
    "Collect points across coffees, beans, and accessories",
    "Unlock seasonal offers and complimentary extras"
  ]
}
```

### Earn points

```http
POST /loyalty/transactions/earn
Content-Type: application/json
```

```json
{
  "email": "guest@talla.example",
  "points": 25,
  "note": "Coffee order"
}
```

### Redeem points

```http
POST /loyalty/transactions/redeem
Content-Type: application/json
```

```json
{
  "email": "guest@talla.example",
  "points": 100,
  "reward": "Free drink"
}
```

## Notes

- Data is stored in `backend/data/loyalty.json`.
- If `DATABASE_URL` is set, the backend uses Postgres for accounts, loyalty records, wallet pass metadata, addresses, vouchers, orders, stock alerts, and alert inbox records.
- If `DATABASE_URL` is set, the backend also records request logs and revocable customer sessions in Postgres.
- Customer-facing protected routes use revocable bearer-backed sessions rather than trusting raw email alone.
- Customer password reset links are hosted at `/password-reset` and require Resend plus a verified sender address.
- For Wallet pass signing on hosted platforms like Render, use `WALLET_P12_BASE64`, `WALLET_P12_PASSWORD`, and `WALLET_WWDR_BASE64`.
- Shopify-backed product control requires a custom app token with `read_products` and `write_products`.
- Completed orders placed in the Talla iOS app are mirrored to Shopify once, using the customer email, preferred delivery phone number, Shopify variant IDs, and quantities. The export does not include EazyPay, BENEFIT, MPGS, transaction IDs, or other payment-provider details.
- Mirrored app orders use Shopify financial status `PENDING`, do not send a receipt, and bypass Shopify inventory adjustment. The payment provider remains the source of payment confirmation in Talla.
- App-order mirroring requires the Shopify custom app token to include `write_orders` and to be an offline Admin API access token.
- Newly created products stay out of the storefront until they are published. Set `SHOPIFY_ADMIN_PUBLICATION_ID` if you want products created from `/admin` to appear in the iOS app automatically.
- This is still a transitional backend, not a final production architecture.
- Before going live, replace the single shared admin credential with a proper multi-user admin model and put the service behind HTTPS.
- The iOS app should point `BackendBaseURL` at this API's public HTTPS URL in production.

## Backup and Restore

For the current Render + Postgres setup, use `pg_dump` for backups and `psql` for restore.

### Create a backup

Use the Render external database URL:

```bash
pg_dump "YOUR_RENDER_EXTERNAL_DATABASE_URL" --format=custom --file=talla-backup.dump
```

If you want a plain SQL export instead:

```bash
pg_dump "YOUR_RENDER_EXTERNAL_DATABASE_URL" --file=talla-backup.sql
```

### Restore a backup

For a custom dump:

```bash
pg_restore --clean --if-exists --no-owner --no-privileges \
  --dbname="YOUR_RENDER_EXTERNAL_DATABASE_URL" \
  talla-backup.dump
```

For a plain SQL backup:

```bash
psql "YOUR_RENDER_EXTERNAL_DATABASE_URL" < talla-backup.sql
```

### Minimum operating procedure

- take a fresh backup before schema or auth changes
- keep at least one dated local copy and one off-machine copy
- test restore into a non-production Postgres database before relying on the backup
- do not run destructive restore commands against production unless you intend to overwrite it

## Database migrations

Schema changes now live in versioned SQL files under:

```text
backend/migrations
```

Run migrations manually with:

```bash
cd backend
npm run migrate
```

The backend also applies pending migrations automatically on startup when `DATABASE_URL` is set.

## Operational alerts

The backend can send automated webhook alerts when production traffic crosses error thresholds.

Required env var:

```text
OPS_ALERT_WEBHOOK_URL=https://your-webhook-endpoint
```

Supported behavior:

- checks `request_logs` on a timer
- sends alerts for elevated 5xx volume
- sends alerts for elevated 429 volume
- respects a cooldown window so the same alert type does not spam repeatedly

This is designed for generic JSON webhooks. It works well with Slack-compatible relays, Discord bridges, or your own small alert receiver.
