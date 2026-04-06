# Terraform State Backend Setup

Creates the Azure Storage Account backend for Terraform remote state.
Azure Blob Storage provides built-in lease-based state locking — no separate lock table required.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Contributor role on the target subscription

## Usage

```bash
# Linux/macOS/WSL
./state-backend.sh prod
./state-backend.sh test
./state-backend.sh dr

# Windows
state-backend.bat prod
state-backend.bat test
state-backend.bat dr
```

## What It Creates

| Resource | Naming Pattern |
|---|---|
| Resource Group | `tfstate-{project_name}-{env}-rg` |
| Storage Account | `tfstate{project_name}{env}{suffix}` (globally unique) |
| Blob Container | `tfstate` |
| State Key | `{project_name}-{env}.tfstate` |

Values are read from `environments/{env}/config/project.tfvars`.

## Generated backend.tfvars

```hcl
resource_group_name  = "tfstate-docintel-prod-rg"
storage_account_name = "tfstatedocintelproabc1"
container_name       = "tfstate"
key                  = "docintel-prod.tfstate"
```

> `backend.tfvars` is git-ignored. Each developer/pipeline generates their own.

## Initialize Terraform

After running the setup script:

```bash
cd environments/prod
./eo-deploy.sh init -backend-config=backend.tfvars
```
