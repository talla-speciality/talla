# Talla Loyalty Backend

Minimal loyalty backend for the iOS app.

## Run

```bash
cd backend
npm start
```

The service starts on `http://127.0.0.1:8787`.

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
- This is a local starter backend, not a production deployment.
- For a production setup, move storage to a database and secure the API with authentication.
