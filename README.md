# ecommerce-api

Basic e-commerce CRUD backend built with **NestJS**, **Prisma (PostgreSQL)**, and **Azure Blob Storage** (Azurite for local development).

## Stack

- NestJS 10
- Prisma 5 + PostgreSQL 16
- `@azure/storage-blob` against Azurite (local emulator)
- `class-validator` for DTO validation
- Multer for `multipart/form-data` image upload

## Prerequisites

- Node.js 20+
- Docker & Docker Compose

## Quick start

```bash
# 1. Copy env
cp .env.example .env

# 2. Start Postgres + Azurite
docker compose up -d

# 3. Install deps
npm install

# 4. Generate Prisma client + run migrations
npm run prisma:migrate -- --name init

# 5. Run the API in watch mode
npm run start:dev
```

The API listens on `http://localhost:3000`.

## Environment variables

See `.env.example`. The default Azurite connection string and key are hardcoded for the emulator and are safe for local dev only — replace with a real Azure Storage account connection string in production.

## API

Base URL: `http://localhost:3000`


| Method | Path            | Body                                        |
| ------ | --------------- | ------------------------------------------- |
| POST   | `/products`     | `multipart/form-data` (fields + `image`)    |
| GET    | `/products`     | —                                           |
| GET    | `/products/:id` | —                                           |
| PATCH  | `/products/:id` | `multipart/form-data` (any field + `image`) |
| DELETE | `/products/:id` | —                                           |


### Create a product

```bash
curl -X POST http://localhost:3000/products \
  -F "name=Coffee Mug" \
  -F "description=Ceramic, 350ml" \
  -F "price=12.99" \
  -F "stock=20" \
  -F "image=@/path/to/photo.jpg"
```

Response:

```json
{
  "id": "…",
  "name": "Coffee Mug",
  "description": "Ceramic, 350ml",
  "price": "12.99",
  "stock": 20,
  "imageUrl": "http://localhost:10000/devstoreaccount1/product-images/…jpg",
  "imageBlob": "…jpg",
  "createdAt": "…",
  "updatedAt": "…"
}
```

Image constraints: PNG/JPEG/WEBP/GIF, max 5 MB.

## Notes

- Updating a product with a new image deletes the previous blob.
- Deleting a product also deletes its blob.
- Azurite blob URLs are reachable only from your host; in production switch the connection string to a real Azure Storage account and the same code will work unchanged.

