# IDP Terraform Environments

Environment-specific Terraform configurations for the Intelligent Document Processing solution. Each environment is fully self-contained with its own state, variables, and deployment scripts.

## Environments

| Environment | Region | Purpose |
|-------------|--------|---------|
| `prod/` | us-east-1 | Production — full feature set, monitoring, DR replication enabled |
| `test/` | us-east-1 | Test — cost-optimised, relaxed security policies, fast teardown |
| `dr/` | us-west-2 | Disaster Recovery — passive standby, receives data from prod |

## Prerequisites

### Terraform

Install Terraform 1.10 or later:

```bash
# macOS (Homebrew)
brew install terraform

# Linux (apt)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify
terraform version
```

### AWS CLI

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Verify
aws --version
```

### AWS Authentication

Choose one method:

**Named profile** (recommended for local development):
```bash
aws configure --profile my-profile
export AWS_PROFILE=my-profile
```

**Environment variables** (CI/CD):
```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

**IAM role** — attach a role with the required permissions to the compute resource; no additional configuration needed.

**AWS SSO**:
```bash
aws configure sso
aws sso login --profile my-profile
```

## Required IAM Permissions

The deploying principal needs permissions to create and manage:

**Compute & Orchestration**
- Lambda functions, layers, event source mappings
- Step Functions state machines and activities
- API Gateway REST APIs, stages, deployments

**Storage**
- S3 buckets, bucket policies, replication configurations
- DynamoDB tables, global secondary indexes

**AI Services**
- Textract (StartDocumentAnalysis, GetDocumentAnalysis)
- Comprehend (DetectEntities, DetectKeyPhrases, DetectPiiEntities)
- SageMaker A2I (human review workflows, work teams) — when human review enabled

**Security & Identity**
- KMS keys, key policies, aliases
- IAM roles, policies, instance profiles
- Cognito user pools, app clients, user groups — when auth enabled
- Secrets Manager secrets

**Networking** (when `lambda_vpc_enabled = true`)
- VPC, subnets, route tables, internet/NAT gateways
- Security groups, VPC endpoints

**Governance & Observability**
- CloudWatch log groups, alarms, dashboards
- SNS topics and subscriptions
- X-Ray groups
- AWS Config recorder and rules — when enabled
- GuardDuty detectors — when enabled
- AWS Backup vaults and plans — when enabled
- AWS Budgets — when enabled

## Configuration File Structure

Each environment shares a consistent layout:

```
environments/<env>/
├── eo-deploy.sh          # Deployment wrapper (Linux/macOS/WSL)
├── eo-deploy.bat         # Deployment wrapper (Windows)
├── main.tf               # Module composition and locals
├── variables.tf          # Variable definitions
├── outputs.tf            # Output values
├── providers.tf          # Provider and version constraints
├── backend.tf            # Remote state backend configuration
└── config/
    ├── application.tfvars    # Lambda, API Gateway, Textract, Comprehend, A2I settings
    ├── best-practices.tfvars # Budgets, Config Rules, GuardDuty
    ├── database.tfvars       # DynamoDB table settings
    ├── dr.tfvars             # AWS Backup vault and S3 cross-region replication
    ├── monitoring.tfvars     # CloudWatch log retention, alarm thresholds, X-Ray
    ├── networking.tfvars     # VPC CIDR, subnets, VPC endpoints, flow logs
    ├── project.tfvars        # Project name, environment, ownership tags
    ├── security.tfvars       # KMS, Cognito policy, security group rules
    └── storage.tfvars        # S3 bucket and DynamoDB capacity settings
```

## Common Tags

All resources are tagged via Terraform provider `default_tags`:

| Tag | Description |
|-----|-------------|
| `Solution` | Full solution name |
| `SolutionAbbr` | Abbreviated identifier |
| `Environment` | prod / test / dr |
| `Provider` | Provider name |
| `Category` | Solution category |
| `Region` | AWS region |
| `ManagedBy` | terraform |
| `CostCenter` | Cost center code |
| `Owner` | Owner email address |
| `ProjectCode` | Project tracking code |

## Quick Start

```bash
cd environments/prod   # or test, dr

# Initialize (first run or after provider/module changes)
./eo-deploy.sh init

# Review planned changes — always do this before apply
./eo-deploy.sh plan

# Apply
./eo-deploy.sh apply
```

See individual environment READMEs for environment-specific guidance:
- [prod/README.md](prod/README.md)
- [test/README.md](test/README.md)
- [dr/README.md](dr/README.md)

## Troubleshooting

**State lock:**
```bash
terraform force-unlock <lock-id>
```

**Backend configuration changed:**
```bash
./eo-deploy.sh init -migrate-state
```

**Credentials error:**
```bash
aws sts get-caller-identity
```

**check block failure at plan time:**
See `terraform/README.md` for the full list of check blocks and how to resolve each.
