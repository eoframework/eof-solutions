# AWS Well-Architected Framework Modules

This directory contains Terraform modules organized by the six pillars of the AWS Well-Architected Framework. These modules implement governance, compliance, and best-practice controls.

## Directory Structure

```
well-architected/
├── operational-excellence/     # Pillar 1: Operational Excellence
│   ├── config-rules/          # AWS Config rules for compliance
│   └── ssm-documents/         # SSM Automation runbooks
├── security/                   # Pillar 2: Security
│   ├── guardduty/             # Threat detection
│   └── security-hub/          # Security posture dashboard
├── reliability/                # Pillar 3: Reliability
│   └── backup-plans/          # AWS Backup plans and vaults
├── performance/                # Pillar 4: Performance Efficiency
│   └── compute-optimizer/     # Right-sizing recommendations
├── cost-optimization/          # Pillar 5: Cost Optimization
│   └── budgets/               # AWS Budgets and alerts
└── sustainability/             # Pillar 6: Sustainability
    └── (future)               # Carbon footprint tracking
```

## Pillar Overview

### Pillar 1: Operational Excellence

**Focus**: Run and monitor systems to deliver business value, continually improve processes and procedures.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `config-rules` | Compliance monitoring, drift detection | AWS Config Rules, Conformance Packs |
| `ssm-documents` | Automated runbooks, remediation | SSM Documents, Automation |

**Design Principles**:
- Perform operations as code
- Make frequent, small, reversible changes
- Refine operations procedures frequently
- Anticipate failure
- Learn from all operational events

### Pillar 2: Security

**Focus**: Protect information, systems, and assets while delivering business value.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `guardduty` | Threat detection and monitoring | GuardDuty Detector, Findings |
| `security-hub` | Security posture aggregation | Security Hub, Standards |

**Design Principles**:
- Implement a strong identity foundation
- Enable traceability
- Apply security at all layers
- Automate security best practices
- Protect data in transit and at rest
- Keep people away from data
- Prepare for security events

### Pillar 3: Reliability

**Focus**: Recover from failures and meet demand.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `backup-plans` | Automated backups, cross-region copy | AWS Backup Vault, Plans, Selections |

**Design Principles**:
- Automatically recover from failure
- Test recovery procedures
- Scale horizontally
- Stop guessing capacity
- Manage change in automation

### Pillar 4: Performance Efficiency

**Focus**: Use computing resources efficiently.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `compute-optimizer` | Right-sizing recommendations | Compute Optimizer enrollment |

**Design Principles**:
- Democratize advanced technologies
- Go global in minutes
- Use serverless architectures
- Experiment more often
- Consider mechanical sympathy

### Pillar 5: Cost Optimization

**Focus**: Avoid unnecessary costs.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `budgets` | Cost alerts and thresholds | AWS Budgets, SNS Notifications |

**Design Principles**:
- Implement cloud financial management
- Adopt a consumption model
- Measure overall efficiency
- Stop spending money on undifferentiated heavy lifting
- Analyze and attribute expenditure

### Pillar 6: Sustainability

**Focus**: Minimize environmental impacts of running cloud workloads.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| (future) | Carbon footprint tracking | Customer Carbon Footprint Tool |

**Design Principles**:
- Understand your impact
- Establish sustainability goals
- Maximize utilization
- Anticipate and adopt new, more efficient offerings
- Use managed services
- Reduce downstream impact

## Usage

### Environment-Specific Deployment

These modules are composed at the environment level based on requirements:

```hcl
# environments/prod/well-architected.tf

module "config_rules" {
  source = "../../modules/aws/well-architected/operational-excellence/config-rules"

  name_prefix = local.name_prefix
  common_tags = local.all_tags

  # Enable CIS AWS Foundations Benchmark
  enable_cis_benchmark = true

  # Resources to monitor
  vpc_id = module.core.vpc_id
  rds_identifiers = [module.database.rds_identifier]
}

module "guardduty" {
  source = "../../modules/aws/well-architected/security/guardduty"

  name_prefix = local.name_prefix
  common_tags = local.all_tags

  enable_malware_protection = true
  enable_s3_protection      = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

module "backup_plans" {
  source = "../../modules/aws/well-architected/reliability/backup-plans"

  name_prefix = local.name_prefix
  common_tags = local.all_tags

  # Daily backups, 30-day retention, cross-region copy
  backup_retention_days = 30
  enable_cross_region_copy = true
  copy_destination_region = "us-west-2"

  # Resources to backup
  rds_arns = [module.database.rds_arn]
  ebs_volume_tags = { Backup = "true" }
}

module "budgets" {
  source = "../../modules/aws/well-architected/cost-optimization/budgets"

  name_prefix = local.name_prefix
  common_tags = local.all_tags

  monthly_budget_amount = 5000
  alert_thresholds      = [50, 80, 100]
  alert_emails          = [var.owner_email]
}
```

### Recommended Configuration by Environment

| Module | test | prod | dr |
|--------|------|------|-----|
| `config-rules` | Optional | Required | Required |
| `guardduty` | Optional | Required | Required |
| `security-hub` | Optional | Required | Optional |
| `backup-plans` | Minimal | Full | Full |
| `budgets` | Required | Required | Required |

## Integration with Core Modules

These Well-Architected modules complement (not replace) the core infrastructure modules:

```
modules/aws/
├── vpc/              # Core networking (Reliability, Security)
├── rds/              # Database (Reliability, Security, Performance)
├── elasticache/      # Caching (Performance, Reliability)
├── kms/              # Encryption (Security)
├── waf/              # Web protection (Security)
├── cloudwatch/       # Monitoring (Operational Excellence)
└── well-architected/ # Governance & Compliance (All Pillars)
```

The core modules implement **preventive controls** (encryption, security groups).
The well-architected modules implement **detective controls** (compliance checks, threat detection).

## Compliance Mapping

| Compliance Framework | Relevant Modules |
|---------------------|------------------|
| CIS AWS Foundations | config-rules, security-hub, guardduty |
| AWS Foundational Security | security-hub, config-rules |
| PCI DSS | config-rules, guardduty, backup-plans |
| HIPAA | config-rules, backup-plans, guardduty |
| SOC 2 | config-rules, guardduty, backup-plans |

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Well-Architected Tool](https://aws.amazon.com/well-architected-tool/)
- [AWS Well-Architected Lenses](https://docs.aws.amazon.com/wellarchitected/latest/userguide/lenses.html)
