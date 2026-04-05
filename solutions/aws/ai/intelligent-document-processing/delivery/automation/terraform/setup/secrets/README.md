# IDP Secrets Setup

Pre-provisions Secrets Manager secrets before deploying the main IDP infrastructure. Run once per environment before the first `terraform apply` in `environments/<env>`.

## Directory Structure

```
setup/secrets/
├── modules/secrets/    # Reusable secrets module
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── prod/               # Production secrets (us-east-1)
│   └── main.tf
├── test/               # Test secrets (us-east-1)
│   └── main.tf
├── dr/                 # DR secrets (us-west-2)
│   └── main.tf
└── README.md
```

## Secrets Created

| Secret | Type | Name Pattern | Purpose |
|--------|------|--------------|---------|
| API Key | Secrets Manager | `{prefix}-api-key` | External integrations calling IDP REST API |
| Workteam Credentials | Secrets Manager | `{prefix}-workteam-credentials` | SageMaker A2I private workforce (prod + dr only) |

## Environment Differences

| Setting | Production | Test | DR |
|---------|------------|------|----|
| Name prefix | `idp-prod` | `idp-test` | `idp-dr` |
| AWS region | us-east-1 | us-east-1 | us-west-2 |
| KMS key | Dedicated | AWS managed | Dedicated |
| API key secret | Yes | Yes | Yes |
| Workteam secret | Yes | No | Yes |
| Recovery window | 7 days | Immediate (0) | 7 days |

## Deploying Secrets

### Production

```bash
cd setup/secrets/prod
terraform init
terraform apply
```

### Test

```bash
cd setup/secrets/test
terraform init
terraform apply
```

### DR

```bash
cd setup/secrets/dr
terraform init
terraform apply
```

## Retrieving Secret Values

### API Key

```bash
# Production
aws secretsmanager get-secret-value \
  --secret-id idp-prod-api-key \
  --query SecretString \
  --output text

# Test
aws secretsmanager get-secret-value \
  --secret-id idp-test-api-key \
  --query SecretString \
  --output text

# DR (us-west-2)
aws secretsmanager get-secret-value \
  --secret-id idp-dr-api-key \
  --region us-west-2 \
  --query SecretString \
  --output text
```

### Workteam Credentials

The workteam secret is created with a placeholder value. Update it with the actual SageMaker A2I workteam ARN before enabling human review:

```bash
aws secretsmanager put-secret-value \
  --secret-id idp-prod-workteam-credentials \
  --secret-string '{"workteam_arn": "arn:aws:sagemaker:us-east-1:ACCOUNT:workteam/private-crowd/TEAM_NAME"}'
```

## Security Notes

1. **State file** — Terraform state contains secret metadata (ARNs, names) but not actual secret values
2. **KMS encryption** — Production and DR secrets use a dedicated per-environment KMS key; test uses AWS managed key
3. **Recovery window** — Production and DR have a 7-day recovery window; test allows immediate deletion for faster teardown

## Cleanup

### Test

```bash
cd setup/secrets/test
terraform destroy
# Secrets are deleted immediately (recovery_window = 0)
```

### Production / DR

```bash
cd setup/secrets/prod   # or dr
terraform destroy
# Secrets enter 7-day pending deletion — can be recovered within that window
```

To force immediate deletion without recovery window:
```bash
aws secretsmanager delete-secret \
  --secret-id idp-prod-api-key \
  --force-delete-without-recovery
```
