# LocalMarket - API Contract

This file is the **agreement between the backend and the frontend**. The backend
must behave exactly like this, and the frontend may rely on exactly this.
If something needs to change, change this file first, then the code.

Endpoints marked **(+)** are additions to the list in SRS Section 5.2. They are
needed to make the app usable (for example, listing categories).

## Conventions

| Topic | Rule |
|---|---|
| Base URL | `http://localhost:5000/api` |
| Body format | JSON, with header `Content-Type: application/json` |
| Logged-in requests | Header `Authorization: Bearer <token>` (token comes from login) |
| Success | `200 OK`, or `201 Created` after creating something |
| Error body | Always `{ "error": "human readable message" }` |
| Money | Numbers, e.g. `85000` or `1500.5` (never strings) |
| Dates | ISO strings, e.g. `"2026-10-23T21:05:34.000Z"` |

### Status codes used

| Code | Meaning in this API |
|---|---|
| 400 | Bad input (missing or invalid field) |
| 401 | Not logged in, or token missing / invalid / expired |
| 403 | Logged in, but not allowed (wrong role, or not your ad) |
| 404 | Thing does not exist (or is not visible to you) |
| 409 | Conflict (email already used, ad already saved, wrong ad status) |
| 500 | Server bug. Body is always `{ "error": "Internal server error" }` |

### Roles

`user` (browse, favorite), `business` (also post and promote ads), `admin`
(moderate). Guests (no token) can only browse and search.
The `admin` role can **not** be chosen at registration; admin accounts are seeded.

### Ad visibility

Public listings and search show only ads with status `approved` or `promoted`.
`promoted` ads are listed first, then newest first.

---

## Slice 0 - Health check

### `GET /health`
Public. Proves the server and database are working.

Response `200`:
```json
{ "status": "ok", "database": "connected", "result": 2 }
```

---

## Slice 1 - Accounts

### `POST /auth/register`
Public.
```json
{ "name": "Ali Khan", "email": "ali@example.com", "password": "secret123", "role": "business" }
```
`role` is `"user"` or `"business"`. Password: at least 6 characters.

Response `201`:
```json
{ "user": { "user_id": 1, "name": "Ali Khan", "email": "ali@example.com", "role": "business" } }
```
Errors: `400` missing field / bad role / short password, `409` email already registered.

### `POST /auth/login`
Public.
```json
{ "email": "ali@example.com", "password": "secret123" }
```
Response `200`:
```json
{ "token": "<jwt>", "user": { "user_id": 1, "name": "Ali Khan", "email": "ali@example.com", "role": "business" } }
```
Errors: `400` missing field, `401` wrong email or password (same message for both).

### `GET /auth/me` **(+)**
Needs login. Returns who the token belongs to.

Response `200`: `{ "user": { "user_id": 1, "name": "...", "email": "...", "role": "business" } }`

### `POST /business` **(+)**
Needs login, role `business`. Creates the business profile (one per user).
```json
{ "business_name": "Ali Traders", "city": "Karachi", "phone": "0300-1234567" }
```
`phone` is optional.

Response `201`:
```json
{ "business": { "business_id": 1, "business_name": "Ali Traders", "city": "Karachi", "phone": "0300-1234567", "verified": false } }
```
Errors: `400`, `403` not a business account, `409` profile already exists.

### `GET /business/me` **(+)**
Needs login, role `business`. Response `200`: `{ "business": { ... same shape ... } }`.
Error: `404` if no profile yet.

---

## Slice 2 - Ads

### `GET /categories` **(+)**
Public. Response `200`:
```json
{ "categories": [ { "category_id": 1, "name": "Electronics", "slug": "electronics" } ] }
```

### `POST /ads`
Needs login, role `business`, and an existing business profile.
```json
{
  "title": "iPhone 12, 128GB",
  "description": "Excellent condition, box included",
  "price": 85000,
  "category_id": 1,
  "city": "Karachi",
  "image_urls": ["https://example.com/1.jpg"]
}
```
`description` and `image_urls` are optional.

Response `201`:
```json
{ "ad": { "ad_id": 42, "status": "pending" } }
```
Errors: `400` missing/invalid field or unknown `category_id`, `403` no business profile.

### `GET /ads`
Public. Optional query parameters (all combine with AND):
`keyword` (title or description), `category_id`, `city`, `min_price`, `max_price`.

Example: `/ads?keyword=iphone&city=Karachi&max_price=100000`

Response `200`:
```json
{
  "ads": [
    {
      "ad_id": 42, "title": "iPhone 12, 128GB", "description": "...",
      "price": 85000, "city": "Karachi", "status": "approved",
      "created_at": "2026-10-23T21:05:34.000Z",
      "business_name": "Ali Traders", "category_name": "Electronics",
      "image_url": "https://example.com/1.jpg"
    }
  ]
}
```
`image_url` is the first image, or `null` if the ad has none. No matches gives `{ "ads": [] }`.

### `GET /ads/mine` **(+)**
Needs login, role `business`. Same shape as `GET /ads`, but only **your** ads and
**every** status (so you can see `pending` and `rejected` ones).

### `GET /ads/:id`
Public. Response `200`:
```json
{
  "ad": {
    "ad_id": 42, "title": "...", "description": "...", "price": 85000,
    "city": "Karachi", "status": "approved", "created_at": "...",
    "category_name": "Electronics",
    "images": ["https://example.com/1.jpg"],
    "business": { "business_id": 1, "business_name": "Ali Traders", "city": "Karachi", "phone": "0300-1234567" }
  }
}
```
Error: `404` if the ad does not exist or is not `approved`/`promoted`.

---

## Slice 3 - Promotions (the transaction)

### `POST /payments`
Needs login, role `business`. Simulated payment that promotes one of **your** ads.
```json
{ "ad_id": 42, "amount": 500 }
```
Both steps below happen inside **one SQL transaction**: insert the payment row,
then set the ad's status to `promoted`. Either both succeed or neither does.

Response `201`:
```json
{
  "payment": { "payment_id": 7, "ad_id": 42, "amount": 500, "status": "completed" },
  "ad": { "ad_id": 42, "status": "promoted" }
}
```
Errors: `400` bad `ad_id` or `amount` (must be > 0), `403` the ad is not yours,
`404` ad not found, `409` ad is not `approved` (only approved ads can be promoted).

---

## Slice 4 - Reports (the aggregate queries)

### `GET /reports/ads-per-category` **(+)**
Public. Number of visible ads per category (categories with zero ads included).
```json
{ "rows": [ { "category": "Electronics", "total_ads": 12 } ] }
```

### `GET /reports/spend-per-business` **(+)**
Needs login, role `admin`. Total simulated spend per business.
```json
{ "rows": [ { "business_name": "Ali Traders", "payments": 3, "total_spent": 1500 } ] }
```

---

## Slice 5 - Favorites

### `POST /favorites`
Needs login (any role). `{ "ad_id": 42 }` -> `201 { "message": "Saved" }`.
Errors: `404` ad not found, `409` already saved.

### `DELETE /favorites/:adId`
Needs login. Response `204` (no body). Error: `404` if it was not saved.

### `GET /favorites`
Needs login. Response `200`: `{ "ads": [ ...same shape as GET /ads... ] }` (the user's saved ads).

---

## Slice 6 - Admin moderation

### `GET /admin/ads?status=pending`
Needs login, role `admin`. `status` defaults to `pending`.
Response `200`: `{ "ads": [ ...same shape as GET /ads... ] }`

### `PUT /admin/ads/:id`
Needs login, role `admin`.
```json
{ "decision": "approve" }
```
`decision` is `"approve"`, `"reject"` or `"remove"`.

| decision | allowed when current status is | new status |
|---|---|---|
| approve | pending | approved |
| reject  | pending | rejected |
| remove  | approved or promoted | removed |

Response `200`: `{ "ad": { "ad_id": 42, "status": "approved" } }`
Errors: `400` bad decision, `404` ad not found, `409` decision not allowed from the current status.
