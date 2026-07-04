# ecommerce-api Helm chart

This chart packages the NestJS ecommerce API for Kubernetes.

The default values are local/minikube-friendly:

- API image: `ecommerce-learn-api:latest`
- in-cluster Postgres enabled
- in-cluster Azurite enabled
- API exposed as a `ClusterIP` service
- ingress disabled

## Local minikube flow

Build the image into minikube:

```bash
eval "$(minikube docker-env)"
docker build -t ecommerce-learn-api:latest .
```

Install or upgrade the release:

```bash
helm upgrade --install ecommerce-api ./helm/ecommerce-api -f ./helm/ecommerce-api/values.local.yaml
```

Access the API:

```bash
kubectl port-forward service/ecommerce-api 3000:80
curl http://localhost:3000/health
```

Inspect:

```bash
kubectl get pods
kubectl get svc
kubectl get pvc
helm status ecommerce-api
```

Uninstall:

```bash
helm uninstall ecommerce-api
```

PVCs may remain depending on your cluster reclaim policy. Check them with:

```bash
kubectl get pvc
```

## Production-shaped flow

Production should normally use managed Postgres and real Azure Blob Storage
instead of the in-cluster learning dependencies.

Create a Kubernetes Secret named `ecommerce-api-secrets` with:

- `DATABASE_URL`
- `AZURE_STORAGE_CONNECTION_STRING`

Then deploy with:

```bash
helm upgrade --install ecommerce-api ./helm/ecommerce-api -f ./helm/ecommerce-api/values.prod.yaml
```

Before using `values.prod.yaml`, replace:

- `<ACR_NAME>`
- `<IMAGE_TAG>`
- `api.example.com`

## Migration job

The chart includes an optional Prisma migration Job:

```yaml
migrationJob:
  enabled: true
```

The current Docker entrypoint already runs `prisma migrate deploy`, so leave the
Job disabled unless you intentionally move migrations out of `entrypoint.sh` or
accept the redundant migration call.
