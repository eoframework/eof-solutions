# IDP Terraform Automation

Infrastructure as Code for deploying the Intelligent Document Processing (IDP) solution on AWS using Terraform.

## Directory Structure

```
terraform/
├── environments/
│   ├── prod/           # Production environment
│   ├── test/           # Test environment
│   └── dr/             # Disaster Recovery environment (passive standby)
├── modules/
│   ├── api/            # API Gateway + Lambda (REST interface)
│   ├── best-practices/ # AWS Budgets, Config Rules, GuardDuty
│   ├── document-processing/ # Step Functions + Textract + Comprehend + Lambda
│   ├── dr/             # AWS Backup vault + S3 cross-region replication
│   ├── human-review/   # SageMaker A2I human review workflow
│   ├── monitoring/     # CloudWatch alarms and dashboards
│   ├── networking/     # VPC, subnets, NAT gateway, VPC endpoints, flow logs
│   ├── security/       # KMS key, security groups
│   ├── storage/        # S3 buckets + DynamoDB tables
│   └── aws/
│       ├── cognito/    # Cognito user pool + app clients
│       └── lambda/     # Lambda function wrapper (arm64, structured logging)
└── setup/
    ├── backend/        # S3 + DynamoDB remote state backend
    └── secrets/        # Pre-provisioned Secrets Manager secrets
        ├── prod/
        ├── test/
        └── dr/
```

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| Terraform | 1.10+ | Infrastructure provisioning |
| AWS CLI | 2.x | Authentication and operational commands |
| Bash | 4.x | `eo-deploy.sh` (Linux/macOS/WSL) |
| PowerShell | 5.1+ | `eo-deploy.bat` (Windows) |

AWS provider `~> 6.0` is pinned in each environment's `providers.tf`.

## AWS Authentication

```bash
# Option 1: Named profile
export AWS_PROFILE=your-profile-name

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Option 3: IAM role (recommended for CI/CD — uses instance/task role automatically)
```

## First-Time Setup

Before deploying an environment for the first time:

1. **Provision remote state backend** (once per account):
   ```bash
   cd setup/backend
   terraform init && terraform apply
   ```

2. **Pre-provision secrets** (once per environment):
   ```bash
   cd setup/secrets/prod   # or test, dr
   terraform init && terraform apply
   ```
   This creates the KMS key and Secrets Manager secrets that the main stack references.

## Deploying an Environment

```bash
cd environments/prod   # or test, dr

# Initialize (downloads providers and modules)
./eo-deploy.sh init        # Linux/macOS/WSL
eo-deploy.bat init         # Windows

# Review planned changes
./eo-deploy.sh plan

# Apply
./eo-deploy.sh apply
```

## Configuration Files

Each environment's `config/` directory contains modular `.tfvars` files loaded automatically by `eo-deploy.sh`:

| File | Purpose |
|------|---------|
| `application.tfvars` | Lambda runtime, API Gateway settings, Textract/Comprehend options, human review |
| `best-practices.tfvars` | AWS Budgets, Config Rules, GuardDuty |
| `database.tfvars` | DynamoDB table settings |
| `dr.tfvars` | AWS Backup vault and S3 cross-region replication |
| `monitoring.tfvars` | CloudWatch log retention, alarm thresholds, X-Ray tracing |
| `networking.tfvars` | VPC CIDR, subnets, VPC endpoint configuration, flow logs |
| `project.tfvars` | Project name, environment identifier, ownership tags |
| `security.tfvars` | KMS settings, Cognito password policy, security group rules |
| `storage.tfvars` | S3 bucket settings, DynamoDB capacity mode |

## Environment Comparison

| Aspect | Test | Prod | DR |
|--------|------|------|-----|
| VPC CIDR | 10.20.0.0/16 | 10.10.0.0/16 | 10.30.0.0/16 |
| Lambda VPC mode | Disabled | Configurable | Configurable |
| Human review (A2I) | Disabled | Enabled | Enabled |
| DR replication | Disabled | S3 CRR + Backup | Receives from Prod |
| Monitoring alarms | Disabled | Enabled (SNS required) | Enabled (SNS required) |
| GuardDuty | Disabled | Enabled | Enabled |
| Config Rules | Disabled | Enabled | Enabled |
| KMS deletion window | 7 days | 30 days | 30 days |
| Secret recovery window | Immediate | 7 days | 7 days |
| Lambda runtime | python3.12 / arm64 | python3.12 / arm64 | python3.12 / arm64 |

## The eo-deploy Script

`eo-deploy.sh` / `eo-deploy.bat` wraps Terraform to automatically load all `config/*.tfvars` files and provide consistent output formatting.

### Commands

| Command | Description |
|---------|-------------|
| `init` | Initialize working directory |
| `plan` | Show execution plan |
| `apply` | Apply configuration |
| `destroy` | Destroy all managed resources |
| `validate` | Validate configuration syntax |
| `fmt` | Format `.tf` files |
| `output` | Show output values |
| `show` | Show current state |
| `state` | State management subcommands |
| `refresh` | Sync state with actual infrastructure |
| `version` | Show Terraform version |

Additional arguments pass through to Terraform:

```bash
./eo-deploy.sh apply -auto-approve
./eo-deploy.sh plan -target=module.storage
./eo-deploy.sh destroy -target=module.storage
```

## DR Runbook

The DR environment is a passive standby. To activate:

1. Restore DynamoDB tables from the latest AWS Backup recovery point in `us-west-2`.
2. Verify S3 documents bucket has received replicated objects from prod.
3. Update DNS / API clients to point to the DR API Gateway endpoint.
4. Confirm Cognito users — DR has an independent user pool; users may need to re-register or be imported.

See `environments/dr/README.md` for full failover procedures.

## Troubleshooting

**State lock:**
```bash
terraform force-unlock <lock-id>
```

**Authentication:**
```bash
aws sts get-caller-identity
```

**Provider or module update:**
```bash
./eo-deploy.sh init -upgrade
```

**check block failure at plan time:**
Terraform `check` blocks validate variable combinations before applying. Common failures:
- `alarms_require_sns_topic` — set `monitoring.sns_topic_arn` in `monitoring.tfvars` before enabling alarms
- `budget_requires_alert_emails` — add at least one email to `budget.alert_emails` in `best-practices.tfvars`
- `regions_are_distinct` — `aws.region` and `aws.dr_region` must differ
- `prod_storage_force_destroy_disabled` — `storage.force_destroy` must be `false` in prod

## References

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- Environment-specific READMEs in each `environments/<env>/README.md`
