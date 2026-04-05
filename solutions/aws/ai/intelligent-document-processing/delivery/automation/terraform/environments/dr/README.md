# DR Environment — Intelligent Document Processing

Terraform configuration for the **disaster recovery** environment. This is a passive standby in `us-west-2` that can assume production workloads if `us-east-1` becomes unavailable.

## DR Strategy

IDP is serverless — there are no EC2 instances, RDS databases, or load balancers to restore. Recovery focuses on data and configuration:

| Component | DR Approach | RTO |
|-----------|-------------|-----|
| **S3 documents** | Continuous S3 Cross-Region Replication from prod | Near-zero data loss |
| **DynamoDB tables** | Restored from AWS Backup cross-region copy point | Minutes (restore job) |
| **Lambda functions** | Stateless — already deployed in DR via Terraform | Immediate |
| **Step Functions** | Stateless — already deployed in DR via Terraform | Immediate |
| **API Gateway** | Independently deployed in DR | Immediate |
| **Cognito user pool** | Independent DR pool — users may need re-registration | Manual |
| **KMS keys** | Independent DR key | Immediate |

## Architecture

```
PRODUCTION (us-east-1)                    DR (us-west-2)
──────────────────────                    ──────────────

S3 Documents Bucket                       S3 Documents Bucket
  (uploads/, processed/)  ──── CRR ────▶  (receives replicated objects)

DynamoDB Tables             Backup Copy   DynamoDB Tables
  (documents, audit log)   ──────────▶   (restored from recovery point)

Lambda + Step Functions                   Lambda + Step Functions
  (document processing)                   (deployed, idle until failover)

API Gateway                               API Gateway
  (prod endpoint)                         (DR endpoint — update DNS to activate)

Cognito User Pool                         Cognito User Pool
  (prod users)                            (independent pool — see notes)
```

## Environment Differences

| Aspect | Production (us-east-1) | DR (us-west-2) |
|--------|------------------------|----------------|
| VPC CIDR | 10.10.0.0/16 | 10.30.0.0/16 |
| Lambda runtime | python3.12 / arm64 | python3.12 / arm64 |
| Human review (A2I) | Enabled | Enabled |
| S3 replication | Sends via CRR | Receives from Prod |
| DR Backup vault | Not present | Enabled (receives copies) |
| Backup plans | Creates + ships cross-region | Not present (receives only) |
| Monitoring alarms | Enabled | Enabled (SNS required) |
| GuardDuty | Enabled | Enabled |
| Config Rules | Enabled | Enabled |
| KMS deletion window | 30 days | 30 days |

## Configuration Files

| File | Description |
|------|-------------|
| `config/project.tfvars` | AWS region (us-west-2), ownership metadata |
| `config/application.tfvars` | Lambda settings, Textract/Comprehend, A2I |
| `config/networking.tfvars` | VPC 10.30.0.0/16, subnets, VPC endpoints |
| `config/security.tfvars` | KMS, Cognito (independent pool), security groups |
| `config/storage.tfvars` | S3 and DynamoDB settings |
| `config/database.tfvars` | DynamoDB table configuration |
| `config/dr.tfvars` | AWS Backup vault — vault_enabled = true, replication_enabled = false |
| `config/monitoring.tfvars` | CloudWatch alarms, X-Ray (sns_topic_arn required) |
| `config/best-practices.tfvars` | Budgets, Config Rules, GuardDuty |

## Deployment Order

DR depends on prod being deployed first (the S3 CRR destination bucket must exist):

```
Step 1: Deploy DR environment
  cd environments/dr
  ./eo-deploy.sh init && ./eo-deploy.sh apply

Step 2: Enable replication in prod (update dr.tfvars with DR bucket name)
  cd environments/prod
  # Set dr.replication_enabled = true in config/dr.tfvars
  ./eo-deploy.sh apply
```

## Quick Start

```bash
cd environments/dr

./eo-deploy.sh init    # Initialize providers and modules
./eo-deploy.sh plan    # Review — should show no changes on a healthy system
./eo-deploy.sh apply   # Deploy standby infrastructure
```

## Failover Procedure

When production (us-east-1) is unavailable:

### 1. Verify DR is current

```bash
cd environments/dr
./eo-deploy.sh plan   # Confirm no pending infrastructure changes

# Check S3 replication lag
aws s3api get-bucket-replication \
  --bucket idp-prod-documents \
  --region us-east-1

# List recent objects in DR bucket to verify replication
aws s3 ls s3://idp-dr-documents/uploads/ --region us-west-2
```

### 2. Restore DynamoDB from latest backup

```bash
# List recovery points in DR vault
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name "$(terraform -chdir=environments/dr output -raw dr_vault_name)" \
  --region us-west-2

# Start restore job (replace ARN with latest recovery point)
aws backup start-restore-job \
  --recovery-point-arn "arn:aws:backup:us-west-2:ACCOUNT:recovery-point:POINT_ID" \
  --iam-role-arn "$(terraform -chdir=environments/dr output -raw dr_restore_role_arn)" \
  --resource-type DynamoDB \
  --metadata '{"tableName":"idp-dr-documents-restored"}' \
  --region us-west-2
```

### 3. Update API clients to DR endpoint

```bash
# Get the DR API endpoint
terraform -chdir=environments/dr output api_endpoint

# Update DNS record or notify API consumers of the new endpoint
```

### 4. Cognito user access

DR has an independent Cognito user pool. Options:
- **Re-registration**: Direct users to sign up again at the DR endpoint
- **Import users**: Export users from prod backup and import to DR pool via CLI
- **Pre-populated**: If users were pre-migrated as part of DR readiness

### 5. Monitor

```bash
# Watch CloudWatch dashboard for DR environment
aws cloudwatch get-dashboard \
  --dashboard-name "idp-dr-dashboard" \
  --region us-west-2
```

## Failback Procedure

When production is restored:

1. **Verify prod** is healthy: `cd environments/prod && ./eo-deploy.sh plan`
2. **Export any new data** created in DR (DynamoDB exports, S3 sync)
3. **Import data to prod** (application-specific migration)
4. **Switch API clients** back to prod endpoint
5. **Confirm CRR is active** — prod S3 replication resumes automatically

## Troubleshooting

**Credentials for DR region:**
```bash
export AWS_REGION=us-west-2
aws sts get-caller-identity
```

**Backup not appearing in DR vault:**
```bash
# Check copy jobs initiated from prod
aws backup list-copy-jobs --region us-east-1

# Check vault contents in DR
aws backup list-backup-vaults --region us-west-2
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name idp-dr-vault \
  --region us-west-2
```

**S3 replication not flowing:**
```bash
# Verify replication configuration on prod bucket
aws s3api get-bucket-replication \
  --bucket idp-prod-documents \
  --region us-east-1

# Check replication metrics
aws s3api get-bucket-replication-metrics \
  --bucket idp-prod-documents \
  --region us-east-1
```

## Related Documentation

- [Production Environment](../prod/README.md)
- [Test Environment](../test/README.md)
- [Terraform Overview](../../README.md)
