# Test Environment — Intelligent Document Processing

Terraform configuration for the **test** environment. Optimised for development and validation with reduced cost and relaxed security policies.

## Quick Start

```bash
# Initialize (first time or after provider/module changes)
./eo-deploy.sh init      # Linux/macOS/WSL
eo-deploy.bat init       # Windows

# Review planned changes
./eo-deploy.sh plan

# Apply
./eo-deploy.sh apply
```

## Environment Characteristics

| Aspect | Configuration |
|--------|---------------|
| Region | us-east-1 |
| VPC CIDR | 10.20.0.0/16 |
| Lambda runtime | python3.12 / arm64 (Graviton2) |
| Human review (A2I) | Disabled by default |
| DR replication | Disabled |
| Monitoring alarms | Disabled |
| GuardDuty | Disabled |
| Config Rules | Disabled |
| KMS deletion window | 7 days (faster cleanup) |
| Secret recovery window | Immediate (0 days) |
| Cognito MFA | Disabled |
| Cognito password policy | Relaxed (8 chars, no symbols) |
| Step Functions logging | ALL level |
| X-Ray tracing | Enabled |

## Configuration Files

Located in `config/`:

| File | Description |
|------|-------------|
| `application.tfvars` | Lambda settings, API Gateway, Textract, Comprehend |
| `best-practices.tfvars` | Budget and governance (mostly disabled) |
| `database.tfvars` | DynamoDB table configuration |
| `dr.tfvars` | DR disabled (`vault_enabled = false, replication_enabled = false`) |
| `monitoring.tfvars` | CloudWatch retention 7 days, alarms disabled |
| `networking.tfvars` | VPC 10.20.0.0/16, subnets, VPC endpoints |
| `project.tfvars` | Project name, region, ownership tags |
| `security.tfvars` | KMS (7-day deletion), Cognito relaxed policy |
| `storage.tfvars` | S3 with `force_destroy = true` for easy cleanup |

## Common Tasks

### Deploy

```bash
export AWS_PROFILE=test-profile
./eo-deploy.sh init
./eo-deploy.sh plan
./eo-deploy.sh apply
```

### Test document processing

After deployment, upload a document to trigger the processing pipeline:

```bash
# Get the documents bucket name
BUCKET=$(terraform output -raw documents_bucket_name)

# Upload a test document
aws s3 cp test-invoice.pdf s3://${BUCKET}/uploads/test-invoice.pdf

# Watch Step Functions execution
aws stepfunctions list-executions \
  --state-machine-arn "$(terraform output -raw state_machine_arn)" \
  --status-filter RUNNING
```

### Tear down

```bash
# Destroys all resources — S3 force_destroy=true so buckets empty automatically
./eo-deploy.sh destroy
```

## Troubleshooting

**Credentials error:**
```bash
aws sts get-caller-identity
```

**State lock:**
```bash
terraform force-unlock <lock-id>
```

**Module errors after update:**
```bash
./eo-deploy.sh init -upgrade
```

## Related Documentation

- [Environments Overview](../README.md)
- [Production Environment](../prod/README.md)
- [Terraform Overview](../../README.md)
