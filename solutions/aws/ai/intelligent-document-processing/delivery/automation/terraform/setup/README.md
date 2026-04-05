# Terraform Setup

Prerequisite infrastructure that must be provisioned once before deploying the main IDP environments.

## Directory Structure

```
setup/
├── backend/           # Remote state backend (S3 + DynamoDB)
│   ├── state-backend.sh   # Linux/macOS/WSL
│   └── state-backend.bat  # Windows
└── secrets/           # Pre-provisioned secrets (Secrets Manager)
    ├── modules/secrets/   # Reusable secrets module
    ├── prod/              # Production secrets
    ├── test/              # Test secrets
    └── dr/                # DR secrets
```

## Deployment Sequence

Run these in order before deploying a main environment for the first time.

### Step 1: Remote State Backend

Creates the S3 bucket and DynamoDB table for Terraform state storage and locking.

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

### Step 2: Secrets

Pre-provisions the KMS key and Secrets Manager secrets that the main IDP stack references.

```bash
# Production
cd secrets/prod
terraform init && terraform apply

# Test
cd ../test
terraform init && terraform apply

# DR (deploy in us-west-2 — DR region)
cd ../dr
terraform init && terraform apply
```

See [secrets/README.md](secrets/README.md) for what secrets are created.

### Step 3: Deploy Main Environments

After setup is complete, deploy the main infrastructure:

```bash
cd ../../environments/prod
./eo-deploy.sh init
./eo-deploy.sh plan
./eo-deploy.sh apply
```

## Prerequisites

- Terraform >= 1.10.0
- AWS CLI v2 configured with appropriate credentials
- IAM permissions for S3, DynamoDB, Secrets Manager, KMS

## Environment Isolation

Each environment (prod, test, dr) has separate:
- Remote state bucket and lock table
- KMS key and Secrets Manager secrets
- Infrastructure resources

This ensures no cross-environment dependencies outside of intentional DR replication.
