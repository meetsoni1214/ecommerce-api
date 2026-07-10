# Terraform learning stack

This Terraform configuration manages the existing AKS learning environment incrementally.

The resources were created manually first, then imported into Terraform one by one. The goal is to make Terraform the source of truth without recreating the environment.

## Managed resources

- Resource group tags
- AKS cluster
- Azure Container Registry
- Storage account
- `product-images` storage container
- Key Vault base configuration and tags
- PostgreSQL `ecommerce` database
- PostgreSQL firewall rule for Azure services
- `ingress-nginx` Helm release
- `ecommerce-api` Helm release

## Data sources

Some existing resources are also read as data sources so other resources can reference their IDs and properties:

- Resource group
- AKS cluster
- ACR
- PostgreSQL Flexible Server
- Storage account
- Key Vault

The PostgreSQL Flexible Server itself is intentionally not managed as a resource because AzureRM requires the administrator password when password authentication is enabled. Putting that password in Terraform would store it in state.

## State

Terraform state is stored remotely in Azure Blob Storage:

- Storage account: `learnaksbs`
- Container: `tfstate`
- Key: `ecommerce-api/terraform.tfstate`

You need Azure Storage Blob Data Contributor access on the storage account or container to run Terraform commands against the remote state.

## Normal workflow

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

After the environment is in sync, `terraform plan` should show:

```text
No changes. Your infrastructure matches the configuration.
```

If the plan shows changes, read it carefully before applying. For this learning environment, small tag or metadata changes are usually safe; replacement or destroy actions should be treated as a stop sign.

Apply intentional changes with:

```bash
terraform apply
```

## Useful outputs

```bash
terraform output
```

## Important

Do not commit `terraform.tfvars`, `.terraform/`, plan files, or local state backups. Terraform state can contain sensitive infrastructure details.

Application secrets still live outside Terraform for now. The Kubernetes secret `ecommerce-api-secrets` is managed manually and consumed by the Helm release through `secrets.existingSecret`.

External Secrets / Key Vault sync was intentionally deferred and can be added later as a separate learning step.
