# Terraform Setup

Prerequisite infrastructure that must be provisioned once before deploying the main Document Intelligence environments.

## Directory Structure

```
setup/
└── backend/           # Remote state backend (Azure Storage Account)
    ├── state-backend.sh   # Linux/macOS/WSL
    └── state-backend.bat  # Windows
```

## Deployment Sequence

Run this before deploying a main environment for the first time.

### Step 1: Remote State Backend

Creates the Azure Storage Account and Blob Container for Terraform state storage.
Azure Blob Storage provides built-in lease-based state locking — no separate lock table required.

```bash
cd backend/

# Linux/macOS/WSL
./state-backend.sh prod
./state-backend.sh test
./state-backend.sh dr

# Windows
state-backend.bat prod
state-backend.bat test
state-backend.bat dr
```

This generates `backend.tfvars` in each environment directory.

See [backend/README.md](backend/README.md) for configuration details.

### Step 2: Deploy Main Environments

After setup is complete, deploy the main infrastructure:

```bash
cd ../../environments/prod
./eo-deploy.sh init -backend-config=backend.tfvars
./eo-deploy.sh plan
./eo-deploy.sh apply
```

## Prerequisites

- Terraform >= 1.10.0
- Azure CLI installed and authenticated (`az login`)
- Contributor role on the target subscription

## Environment Isolation

Each environment (prod, test, dr) has separate:
- Remote state storage account and container
- Infrastructure resources

This ensures no cross-environment dependencies outside of intentional DR replication.
