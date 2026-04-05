# Terraform Backend Setup

Scripts to create AWS resources for Terraform remote state storage.

## Overview

Terraform remote state requires:
- **S3 Bucket** - Stores state file with versioning and encryption
- **DynamoDB Table** - Provides state locking

These must exist before `terraform init`, so these scripts create them via AWS CLI.

## Naming Convention

| Resource | Pattern | Example |
|----------|---------|---------|
| S3 Bucket | `{org_prefix}-{solution_abbr}-{env}-terraform-state` | `acme-vxr-prod-terraform-state` |
| DynamoDB Table | `{org_prefix}-{solution_abbr}-{env}-terraform-locks` | `acme-vxr-prod-terraform-locks` |

## Prerequisites

1. AWS CLI configured (`aws configure`)
2. `org_prefix` set in `environments/{env}/config/project.tfvars`

## Configuration

Ensure `config/project.tfvars` has:

```hcl
solution_abbr = "vxr"           # 3-4 char abbreviation
org_prefix    = "acme"          # REQUIRED for unique S3 bucket names
aws_region    = "us-east-1"
```

## Usage

### Linux/Mac

```bash
# Specify environment
./setup/state-backend.sh prod

# Or auto-detect from current directory
cd environments/prod
../../setup/state-backend.sh
```

### Windows

```cmd
setup\state-backend.bat prod
```

## What Gets Created

1. **S3 Bucket** with versioning, AES-256 encryption, public access blocked
2. **DynamoDB Table** with `LockID` key, pay-per-request billing
3. **backend.tfvars** file in the environment directory

## After Setup

Initialize Terraform with the generated backend config:

```bash
cd environments/prod
terraform init -backend-config=backend.tfvars
```

Or use `eo-deploy.sh`:

```bash
cd environments/prod
./eo-deploy.sh init
```

## Multi-Environment Setup

Run for each environment:

```bash
./setup/state-backend.sh prod
./setup/state-backend.sh test
./setup/state-backend.sh dr
```

Each gets isolated state storage.

## Troubleshooting

### "org_prefix not found"
Set in `config/project.tfvars`:
```hcl
org_prefix = "mycompany"
```

### "AWS credentials not configured"
```bash
aws configure
```

### "Bucket name already exists"
S3 names are globally unique. Use a more specific `org_prefix`.
