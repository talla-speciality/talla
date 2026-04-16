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
- `ADMIN_USERNAME`: HTTP Basic Auth username for `/admin`
- `ADMIN_PASSWORD`: HTTP Basic Auth password for `/admin`
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

It is protected with HTTP Basic Auth using `ADMIN_USERNAME` and `ADMIN_PASSWORD`.

Current admin capabilities:

- customer lookup by email
- loyalty balance inspection
- manual loyalty point adjustments
- visibility into orders, addresses, vouchers, stock alerts, and inbox records

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
- For Wallet pass signing on hosted platforms like Render, use `WALLET_P12_BASE64`, `WALLET_P12_PASSWORD`, and `WALLET_WWDR_BASE64`.
- This is still a transitional backend, not a final production architecture.
- Before going live, replace HTTP Basic Auth with stronger admin authentication and put the service behind HTTPS.
- The iOS app should point `BackendBaseURL` at this API's public HTTPS URL in production.
