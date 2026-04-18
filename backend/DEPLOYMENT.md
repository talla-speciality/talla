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
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=240
REQUEST_LOGGING_ENABLED=true
SHOPIFY_ADMIN_SHOP_DOMAIN=your-store.myshopify.com
SHOPIFY_ADMIN_ACCESS_TOKEN=shpat_...
SHOPIFY_ADMIN_API_VERSION=2025-10
SHOPIFY_ADMIN_PUBLICATION_ID=gid://shopify/Publication/...
WALLET_PASS_TEMPLATE_DIRECTORY=/app/WalletPass/TallaLoyalty.pass
WALLET_P12_PATH=/run/secrets/talla-wallet.p12
WALLET_P12_BASE64=
WALLET_P12_PASSWORD=your-password
WALLET_WWDR_PATH=/run/secrets/AppleWWDRCAG4.cer
WALLET_WWDR_BASE64=
```

Notes:

- `HOST` should stay `0.0.0.0` in containers
- `APP_URL` should be your real public URL
- `DATA_DIRECTORY` should be backed by persistent storage, not ephemeral container disk
- `DATABASE_URL` should point to your managed Postgres instance
- `ADMIN_USERNAME`, `ADMIN_PASSWORD`, and `ADMIN_SESSION_SECRET` power the admin login and signed session cookie
- `CUSTOMER_TOKEN_SECRET` enables customer session issuance; set it explicitly in production
- `RATE_LIMIT_WINDOW_MS` and `RATE_LIMIT_MAX_REQUESTS` control per-IP request throttling
- `REQUEST_LOGGING_ENABLED=true` records request logs in Postgres for audit and debugging
- `SHOPIFY_ADMIN_SHOP_DOMAIN` and `SHOPIFY_ADMIN_ACCESS_TOKEN` enable live product control from `/admin`
- `SHOPIFY_ADMIN_PUBLICATION_ID` is optional, but without it newly created products may not appear in the storefront-backed iOS app
- Wallet pass signing requires both the signer `.p12` and the WWDR certificate; on Render, a base64 signer cert plus a repo-tracked WWDR file is the most stable setup
- `/admin` now includes an operations snapshot powered by `request_logs`

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

## Important production gaps

This backend is deployable, but not yet production-hardened. Before public launch, you should add:

- refresh token flow instead of a single long-lived customer session token
- stronger admin authentication and authorization than HTTP Basic Auth
- immutable audit review workflow for sensitive admin actions
- operational monitoring on top of the request logs
- rate limiting
- secret management for Wallet signing assets
- automated backups for Postgres
