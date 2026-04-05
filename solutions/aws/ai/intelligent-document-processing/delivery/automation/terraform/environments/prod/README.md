# Production Environment — Intelligent Document Processing

Terraform configuration for the **production** environment. Configured for operational excellence, security, and business continuity.

## Quick Start

```bash
# Initialize (first time or after provider/module changes)
./eo-deploy.sh init      # Linux/macOS/WSL
eo-deploy.bat init       # Windows

# ALWAYS review the plan before applying in production
./eo-deploy.sh plan

# Apply
./eo-deploy.sh apply
```

## Environment Characteristics

| Aspect | Configuration |
|--------|---------------|
| Region | us-east-1 |
| VPC CIDR | 10.10.0.0/16 |
| Lambda runtime | python3.12 / arm64 (Graviton2) |
| Human review (A2I) | Enabled |
| DR replication | S3 CRR + AWS Backup cross-region to us-west-2 |
| Monitoring alarms | Enabled — `sns_topic_arn` required |
| GuardDuty | Enabled with malware protection |
| Config Rules | Enabled with reliability and security rules |
| KMS deletion window | 30 days |
| Secret recovery window | 7 days |
| Step Functions logging | ERROR level |
| X-Ray tracing | Enabled |

## Configuration Files

Located in `config/`:

| File | Description |
|------|-------------|
| `application.tfvars` | Lambda settings, API Gateway, Textract, Comprehend, A2I |
| `best-practices.tfvars` | Budgets, Config Rules, GuardDuty |
| `database.tfvars` | DynamoDB table configuration |
| `dr.tfvars` | AWS Backup vault and S3 cross-region replication |
| `monitoring.tfvars` | CloudWatch retention, alarm thresholds, X-Ray |
| `networking.tfvars` | VPC, subnets, VPC endpoints, flow logs |
| `project.tfvars` | Project name, region, ownership tags |
| `security.tfvars` | KMS, Cognito password policy, security groups |
| `storage.tfvars` | S3 bucket settings, DynamoDB capacity |

## Production Safeguards

### Terraform check blocks

The following checks run at `plan` time and will fail if misconfigured:

- **`alarms_require_sns_topic`** — `monitoring.sns_topic_arn` must be set when `enable_alarms = true`
- **`prod_storage_force_destroy_disabled`** — `storage.force_destroy` must be `false` to prevent data loss
- **`budget_requires_alert_emails`** — at least one email required when budgets are enabled
- **`regions_are_distinct`** — `aws.region` and `aws.dr_region` must be different

### Pre-deployment checklist

- [ ] `terraform plan` reviewed — no unexpected resource replacements or deletions
- [ ] `sns_topic_arn` set in `monitoring.tfvars` (required for alarms)
- [ ] `storage.force_destroy = false` confirmed in `storage.tfvars`
- [ ] DynamoDB changes scheduled — table modifications can cause brief interruptions
- [ ] Team notified of planned deployment window

### Protected resources

The following resources require deliberate action to delete:

- **S3 buckets** — `force_destroy = false` prevents accidental deletion of documents
- **DynamoDB tables** — point-in-time recovery enabled; deletion requires table to be empty
- **KMS keys** — 30-day pending deletion period; cannot be recovered after deletion window
- **Secrets Manager secrets** — 7-day recovery window before permanent deletion

## Common Tasks

### Deploy for the first time

```bash
# 1. Set AWS credentials
export AWS_PROFILE=production

# 2. Run setup (only once — creates remote state and secrets)
cd ../../setup/backend && ./state-backend.sh prod
cd ../secrets/prod && terraform init && terraform apply

# 3. Initialize and deploy
cd ../../environments/prod
./eo-deploy.sh init
./eo-deploy.sh plan
./eo-deploy.sh apply
```

### Update configuration

```bash
# Edit the relevant config/*.tfvars file, then:
./eo-deploy.sh plan    # Review impact
./eo-deploy.sh apply   # Apply during maintenance window
```

### Rollback

```bash
# Restore a previous config from git and re-apply
git checkout HEAD~1 -- config/
./eo-deploy.sh plan
./eo-deploy.sh apply
```

### View outputs

```bash
./eo-deploy.sh output
```

## Troubleshooting

**Credentials error:**
```bash
aws sts get-caller-identity
export AWS_PROFILE=production
```

**State lock:**
```bash
terraform force-unlock <lock-id>
```

**Resource drift:**
```bash
./eo-deploy.sh refresh
./eo-deploy.sh plan
```

## Related Documentation

- [Environments Overview](../README.md)
- [DR Environment](../dr/README.md)
- [Terraform Overview](../../README.md)
