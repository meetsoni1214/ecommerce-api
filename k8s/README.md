# Kubernetes deployment (local / minikube)

Manifests for running `ecommerce-api` end-to-end on a local minikube cluster.
Everything — the API, Postgres, and Azurite (blob storage emulator) — runs
inside the cluster; nothing depends on external managed services.

## Prerequisites

- [`minikube`](https://minikube.sigs.k8s.io/docs/start/)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- [`docker`](https://docs.docker.com/get-docker/) (to build the API image)

## What's in here

| File | Purpose |
| --- | --- |
| `postgres.yaml` | Postgres PVC + Service + Deployment (in-cluster DB) |
| `postgres-secret.yaml` | DB credentials (`POSTGRES_USER`/`PASSWORD`/`DB`) |
| `postgres-configmap.yaml` | Non-sensitive DB connection bits (`POSTGRES_HOST`, `POSTGRES_PORT`) |
| `azurite.yaml` | Azurite PVC + Service + Deployment (in-cluster blob storage) |
| `deployment.yaml` | `ecommerce-api` Deployment + `LoadBalancer` Service |

All resources live in the `default` namespace.

## One-time setup

```bash
# Start the cluster
minikube start
```

## Deploy

### 1. Build the API image into minikube

The Deployment uses `imagePullPolicy: Never`, so the image has to exist
inside minikube's Docker daemon — not just on your host.

```bash
# Point your shell at minikube's docker daemon
eval "$(minikube docker-env)"

# Build directly into minikube
docker build -t ecommerce-learn-api:latest .
```

### 2. Apply the manifests

```bash
kubectl apply -f k8s/
```

This brings up Postgres, Azurite, and the API. The API pod uses an
initContainer to wait for Postgres before starting; migrations
(`prisma migrate deploy`) run on container start via `entrypoint.sh`.

### 3. Verify

```bash
# Watch pods come up
kubectl get pods -w

# Tail API logs
kubectl logs -l app=ecommerce-depl -f
```

### 4. Reach the API

The Service is `type: LoadBalancer` with `nodePort: 30000`. On minikube
the `LoadBalancer` IP stays `<pending>` unless `minikube tunnel` is
running, so the simplest paths are:

```bash
# Option A — print a reachable URL
minikube service ecommerce-api-service --url

# Option B — hit the NodePort directly
curl http://$(minikube ip):30000/health

# Option C — provision a real EXTERNAL-IP (run in a separate terminal)
minikube tunnel
```

## Rolling out a new version

```bash
# Rebuild into minikube
eval "$(minikube docker-env)"
docker build -t ecommerce-learn-api:latest .

# Force the Deployment to pick up the new image
kubectl rollout restart deployment/ecommerce-depl
kubectl rollout status deployment/ecommerce-depl
```

The API Deployment uses `RollingUpdate` (`maxSurge: 25%`,
`maxUnavailable: 25%`). Postgres and Azurite use `Recreate` — they're
single-replica stateful workloads on `ReadWriteOnce` PVCs, where two
pods cannot mount the volume at once.

## Common operations

```bash
# Open a psql shell in the Postgres pod
kubectl exec -it deploy/postgres -- psql -U postgres -d ecommerce

# Inspect the Azurite blob container from inside the cluster
kubectl run -it --rm azcli --image=mcr.microsoft.com/azure-cli --restart=Never -- \
  az storage blob list \
    --container-name product-images \
    --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;"
```

## Teardown

```bash
kubectl delete -f k8s/      # remove all workloads + PVCs
minikube stop               # stop the cluster (preserves state)
minikube delete             # nuke the cluster entirely
```

## Notes

- **Image source.** The API image is built locally and loaded straight
  into minikube's Docker daemon (`eval $(minikube docker-env)`). There
  is no registry involved. If you switch to a remote registry, drop
  `imagePullPolicy: Never` from `deployment.yaml`.
- **Migrations.** `entrypoint.sh` runs `prisma migrate deploy` on every
  pod startup. Prisma's advisory lock makes this safe even with multiple
  replicas, but for cleaner ops you can split migrations into a `Job`
  or `initContainer`.
- **Azurite credentials are public.** The `AccountName=devstoreaccount1`
  and `AccountKey=Eby8…` values are the well-known Azurite dev
  credentials, published in Microsoft's docs. They are not secrets;
  that's why the connection string sits inline in `deployment.yaml`
  rather than in a `Secret`.
- **`postgres-configmap.yaml` only exposes host/port.** Credentials stay
  in `postgres-secret.yaml`; the API composes the full `DATABASE_URL`
  at runtime from both sources (see the `DATABASE_URL` env in
  `deployment.yaml`).
