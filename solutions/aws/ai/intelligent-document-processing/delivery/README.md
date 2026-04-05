# Delivery Resources

Implementation and operational materials for deploying the Intelligent Document Processing solution.

## Documents

| File | Purpose |
|------|---------|
| `detailed-design.docx` | Architecture decisions, component design, data flows |
| `implementation-guide.docx` | Step-by-step deployment procedures and prerequisites |
| `configuration.xlsx` | Environment configuration reference and sizing guide |
| `project-plan.xlsx` | Implementation timeline and workstream breakdown |
| `test-plan.xlsx` | Test cases and acceptance criteria |

Source markdown for all documents is in `raw/` for version control and regeneration.

## Infrastructure Automation

Terraform IaC for deploying all IDP cloud resources:

```
automation/terraform/
├── README.md               # Start here — overview, quick start, prerequisites
├── environments/
│   ├── prod/               # Production (us-east-1)
│   ├── test/               # Test (us-east-1)
│   └── dr/                 # Disaster Recovery (us-west-2)
├── modules/                # Reusable modules (api, storage, security, etc.)
└── setup/
    ├── backend/            # Remote state backend
    └── secrets/            # Pre-provisioned secrets
```

**Start here:** [`automation/terraform/README.md`](automation/terraform/README.md)

## Implementation Workflow

### 1. Planning

- Review `implementation-guide.docx` for prerequisites and environment requirements
- Confirm AWS account access and IAM permissions
- Agree on VPC CIDRs, tagging standards, and ownership metadata

### 2. Setup (one-time)

```bash
cd automation/terraform/setup/backend
./state-backend.sh prod && ./state-backend.sh test && ./state-backend.sh dr

cd ../secrets/prod && terraform init && terraform apply
cd ../test && terraform init && terraform apply
cd ../dr && terraform init && terraform apply
```

### 3. Deployment

```bash
cd automation/terraform/environments/prod
./eo-deploy.sh init
./eo-deploy.sh plan
./eo-deploy.sh apply
```

Repeat for `test` and `dr` environments.

### 4. Validation

- Upload a test document to the S3 `uploads/` prefix and trace through Step Functions
- Validate API Gateway endpoints with the test cases in `test-plan.xlsx`
- Confirm CloudWatch alarms and dashboards are operational

### 5. Handover

- Walk operations team through `automation/terraform/environments/dr/README.md` DR runbook
- Confirm SNS topic subscription for monitoring alarms
- Review ongoing operations — state management, secret rotation, Terraform upgrades

---

**[EO Framework](https://eoframework.org)** — Exceptional Outcome Framework
