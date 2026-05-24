# Containerize the ecommerce-api app

**Date:** 2026-05-24
**Status:** Approved

## Goal

Produce a production-ready Docker image for the NestJS ecommerce-api so it can
be deployed to a registry / Azure / Kubernetes, and integrate it into the
existing `docker-compose.yml` for easy local startup of the full stack
(api + Postgres + Azurite).

## Non-goals

- A dev-mode image with hot reload. Local development continues to use
  `pnpm start:dev` against the existing compose-managed Postgres + Azurite.
- Keeping Azure Key Vault integration active inside the container. Secrets are
  supplied as plain environment variables in containerized deployments. The
  existing `key-vault.ts` loader already no-ops when `KEY_VAULT_URL` is unset,
  so no code changes are required for this.
- Deep liveness/readiness probes that check DB and storage connectivity. The
  health endpoint stays minimal; deeper probes are a follow-up if needed.

## Approach

Multi-stage `Dockerfile` based on `node:20-alpine`, producing a slim runtime
image that contains only production dependencies, the compiled `dist/`, and
the generated Prisma client.

Alpine is chosen because Prisma officially supports it via the
`linux-musl-openssl-3.0.x` binary target and the resulting image is
substantially smaller than Debian-slim (~150–200 MB vs ~1 GB). Distroless was
considered and rejected because Prisma migrations need a shell at startup and
runtime debugging would be harder.

## Dockerfile structure

Three stages:

1. **`deps`** — installs all dependencies and generates the Prisma client.
   - Base: `node:20-alpine`
   - Enables `pnpm` via `corepack`
   - Copies `package.json`, `pnpm-lock.yaml`, `prisma/schema.prisma`
   - Runs `pnpm install --frozen-lockfile`
   - Runs `pnpm prisma generate` so the client is built against the
     Alpine `linux-musl` target

2. **`build`** — compiles TypeScript to `dist/`.
   - Copies source + `node_modules` from `deps`
   - Runs `pnpm build`

3. **`runtime`** — final slim image.
   - Fresh `node:20-alpine`
   - Installs only production deps (`pnpm install --frozen-lockfile --prod`)
   - Copies generated Prisma client from `deps`
   - Copies `dist/` from `build`
   - Copies `prisma/` (schema + migrations) so `prisma migrate deploy` can
     run at container startup
   - Copies `entrypoint.sh`
   - Switches to the non-root `node` user
   - `EXPOSE 3000`
   - `ENTRYPOINT ["./entrypoint.sh"]`, `CMD ["node", "dist/main.js"]`

### Prisma binary target

`prisma/schema.prisma` is updated so the `generator client` block declares:

```
binaryTargets = ["native", "linux-musl-openssl-3.0.x"]
```

`native` preserves local development on the host; `linux-musl-openssl-3.0.x`
matches Alpine's runtime.

### Entrypoint

`entrypoint.sh` runs:

```
#!/bin/sh
set -e
npx prisma migrate deploy
exec "$@"
```

This applies any pending migrations at startup and then execs the command
passed to the container (defaulting to `node dist/main.js`). It is idempotent
and safe to re-run.

## `.dockerignore`

Keeps the build context small and prevents host artifacts from leaking into
the image:

- `node_modules`
- `dist`
- `.git`
- `.env*`
- `*.md`
- `superyou_strawberry.webp`
- `docs/`

## Health endpoint

A minimal endpoint is added so compose (and future orchestrators) can probe
the container.

- New `src/health/health.module.ts` and `src/health/health.controller.ts`
  exposing `GET /health` that returns `{ status: 'ok' }` with HTTP 200.
- No DB or storage probes — these add failure modes (transient blips causing
  restart loops) that are not worth it at this scale.
- `HealthModule` is wired into `app.module.ts`.

## docker-compose.yml changes

Add an `api` service alongside the existing `postgres` and `azurite`:

```yaml
api:
  build: .
  container_name: ecommerce-api
  restart: unless-stopped
  depends_on:
    postgres:
      condition: service_healthy
    azurite:
      condition: service_started
  environment:
    PORT: ${PORT:-3000}
    DATABASE_URL: ${DATABASE_URL}
    AZURE_STORAGE_CONNECTION_STRING: ${AZURE_STORAGE_CONNECTION_STRING}
    AZURE_STORAGE_CONTAINER: ${AZURE_STORAGE_CONTAINER:-products}
  ports:
    - "3000:3000"
  healthcheck:
    test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/health"]
    interval: 10s
    timeout: 5s
    retries: 5
```

`wget` is used because it ships with `node:20-alpine`; avoids adding `curl`.

`KEY_VAULT_URL` is intentionally not passed, so the key-vault loader stays a
no-op in compose.

## Configuration

A new committed `.env.example` documents required variables and provides
working defaults for the compose stack:

```
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/ecommerce?schema=public
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;
AZURE_STORAGE_CONTAINER=products
```

The Azurite account name and key are the well-known emulator defaults and are
only valid against the emulator — safe to commit.

`.env` itself stays gitignored.

## Files changed / created

**New:**

- `Dockerfile`
- `.dockerignore`
- `entrypoint.sh`
- `.env.example`
- `src/health/health.module.ts`
- `src/health/health.controller.ts`

**Modified:**

- `prisma/schema.prisma` — add `binaryTargets` to generator client block
- `docker-compose.yml` — add `api` service + healthcheck
- `src/app.module.ts` — import `HealthModule`
- `.gitignore` — ensure `.env` is ignored
- `README.md` — add a "Run with Docker" section

## Testing

- `docker compose build` succeeds.
- `docker compose up` brings up all three services; `api` becomes healthy.
- `curl localhost:3000/health` returns `{"status":"ok"}`.
- `curl localhost:3000/products` returns `[]` — proves the DB connection and
  that `prisma migrate deploy` ran at startup.
- Final runtime image is under ~250 MB.
- Verify no source files in the final image:
  `docker run --rm --entrypoint sh ecommerce-api -c 'ls /app'` should show
  `dist`, `node_modules`, `prisma`, `package.json` — no `src/`.

## Follow-ups (out of scope)

- Deep health probes (DB + storage) once we know what an orchestrator needs.
- Optional dev-mode image with hot reload, if the team wants compose-only
  development.
- CI workflow to build and push the image to a registry.
