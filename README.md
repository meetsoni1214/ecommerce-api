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

## Run with Docker

The full stack (API + Postgres + Azurite) can be run with one command. Compose
ships with working defaults for the API container, so no `.env` is required.

```bash
docker compose up --build
```

The API container runs `prisma migrate deploy` at startup, so the database is
ready on first boot. A liveness endpoint is exposed at `GET /health`.

The Compose-mode environment for the API service is set directly in
`docker-compose.yml` so the local `.env` (which targets host-mode `localhost`)
does not interfere. To point the container at a real database or storage
account, edit the `environment:` block in `docker-compose.yml`.

## Environment variables

See `.env.example`. The default Azurite connection string and key are hardcoded for the emulator and are safe for local dev only — replace with a real Azure Storage account connection string in production.

## Azure VM + Key Vault

In production, set `KEY_VAULT_URL` on the VM and keep secrets in Azure Key Vault. The app uses `DefaultAzureCredential`, so an Azure VM should use a managed identity with the `Key Vault Secrets User` role on the vault.

```bash
az vm identity assign \
  --resource-group <resource-group> \
  --name <vm-name>

VM_PRINCIPAL_ID=$(az vm show \
  --resource-group <resource-group> \
  --name <vm-name> \
  --query identity.principalId \
  -o tsv)

KV_ID=$(az keyvault show \
  --resource-group <resource-group> \
  --name <key-vault-name> \
  --query id \
  -o tsv)

az role assignment create \
  --assignee "$VM_PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope "$KV_ID"
```

By default, the app loads these missing environment variables from Key Vault before NestJS starts:

- `DATABASE_URL` from secret `DATABASE-URL`
- `AZURE_STORAGE_CONNECTION_STRING` from secret `AZURE-STORAGE-CONNECTION-STRING`

Set `KEY_VAULT_SECRETS` to a comma-separated list to load more values. A secret name defaults to the environment variable name with underscores replaced by hyphens; override any specific mapping with `KEY_VAULT_SECRET_NAME_<ENV_NAME>`.

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

