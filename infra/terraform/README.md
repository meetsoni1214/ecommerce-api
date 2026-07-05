# Terraform learning stack

This is currently a read-only Terraform inventory for the existing AKS learning environment.

It reads these existing Azure resources as data sources:

- resource group
- AKS cluster
- ACR
- PostgreSQL Flexible Server
- Storage account
- Key Vault

It intentionally creates no Azure resources right now. External Secrets wiring was removed so it can be revisited later.

## First run

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

The plan should show no resources to create, update, or destroy.

## Useful outputs

```bash
terraform output
```

## Important

Do not commit `terraform.tfvars`, `.terraform/`, or `terraform.tfstate`. Terraform state can contain sensitive infrastructure details.
