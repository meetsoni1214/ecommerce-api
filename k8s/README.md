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
| `migration-job.yaml` | One-time Prisma migration Job |
| `deployment.yaml` | `ecommerce-api` Deployment + `ClusterIP` Service |

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

### 2. Start dependencies and run migrations

```bash
kubectl apply \
  -f k8s/postgres-secret.yaml \
  -f k8s/postgres-configmap.yaml \
  -f k8s/postgres.yaml \
  -f k8s/azurite.yaml

kubectl rollout status deployment/postgres

kubectl delete job ecommerce-migrate --ignore-not-found
kubectl apply -f k8s/migration-job.yaml
kubectl wait --for=condition=complete job/ecommerce-migrate --timeout=120s
kubectl logs job/ecommerce-migrate
```

The migration Job must complete successfully before starting the API.

### 3. Start the API

```bash
kubectl apply -f k8s/deployment.yaml -f k8s/ingress.yaml
```

### 4. Verify

```bash
# Watch pods come up
kubectl get pods -w

# Tail API logs
kubectl logs -l app=ecommerce-depl -f
```

### 5. Reach the API

The Service is `ClusterIP`, so use a local port-forward:

```bash
kubectl port-forward service/ecommerce-api-service 3000:80
curl http://localhost:3000/health
```

## Rolling out a new version

```bash
# Rebuild into minikube
eval "$(minikube docker-env)"
docker build -t ecommerce-learn-api:latest .

# Apply pending migrations before updating the API
kubectl delete job ecommerce-migrate --ignore-not-found
kubectl apply -f k8s/migration-job.yaml
kubectl wait --for=condition=complete job/ecommerce-migrate --timeout=120s
kubectl logs job/ecommerce-migrate

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
kubectl delete \
  -f k8s/ingress.yaml \
  -f k8s/deployment.yaml \
  -f k8s/migration-job.yaml \
  -f k8s/azurite.yaml \
  -f k8s/postgres.yaml \
  -f k8s/postgres-configmap.yaml \
  -f k8s/postgres-secret.yaml
minikube stop
minikube delete
```

## Notes

- **Image source.** The API image is built locally and loaded straight
  into minikube's Docker daemon (`eval $(minikube docker-env)`). There
  is no registry involved. If you switch to a remote registry, drop
  `imagePullPolicy: Never` from `deployment.yaml`.
- **Migrations.** `migration-job.yaml` runs `prisma migrate deploy`
  before the API Deployment is installed or restarted. API pod restarts
  do not run migrations.
- **Azurite credentials are public.** The `AccountName=devstoreaccount1`
  and `AccountKey=Eby8…` values are the well-known Azurite dev
  credentials, published in Microsoft's docs. They are not secrets;
  that's why the connection string sits inline in `deployment.yaml`
  rather than in a `Secret`.
- **`postgres-configmap.yaml` only exposes host/port.** Credentials stay
  in `postgres-secret.yaml`; the API composes the full `DATABASE_URL`
  at runtime from both sources (see the `DATABASE_URL` env in
  `deployment.yaml`).
