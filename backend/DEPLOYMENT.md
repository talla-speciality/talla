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
- `DATABASE_URL` should point to your managed Postgres instance once you move beyond JSON storage
- Wallet pass signing requires both the signer `.p12` and the WWDR certificate; on Render, base64 env vars are usually easier than mounting files

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

## Important production gaps

This backend is deployable, but not yet production-hardened. Before public launch, you should add:

- add authentication/session tokens and admin authorization on top of the now database-backed backend
- customer authentication tokens instead of email-only access patterns
- admin authentication and authorization
- request logging and monitoring
- rate limiting
- secret management for Wallet signing assets
- backups for data storage
