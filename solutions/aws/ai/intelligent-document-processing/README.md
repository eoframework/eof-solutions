# Intelligent Document Processing

**Provider:** AWS | **Category:** AI | **Version:** 1.0.0 | **Status:** Production Ready

## Solution Overview

Organizations process thousands of documents daily — invoices, contracts, forms, and reports — requiring manual data entry and review. This manual processing is slow, error-prone, and prevents teams from focusing on higher-value work.

This solution uses AWS AI services to automatically extract text, forms, and tables from documents, identify key data points, classify document types, and route them based on content — with optional human review for low-confidence results.

### Key Benefits

| Benefit | Impact |
|---------|--------|
| Processing Time | 95% reduction |
| Data Extraction Accuracy | 99%+ |
| Cost Savings | 70% reduction in manual processing costs |

### Core Technologies

- **Amazon Textract** — Document text, form, and table extraction
- **Amazon Comprehend** — Entity detection, key phrase extraction, PII identification
- **AWS Step Functions** — Serverless orchestration of the processing pipeline
- **AWS Lambda** — Stateless compute for each pipeline stage (python3.12, arm64)
- **Amazon S3** — Secure document storage with optional cross-region replication
- **Amazon DynamoDB** — Document processing status and results
- **Amazon API Gateway** — REST API for document upload and status queries
- **Amazon Cognito** — User authentication and access control
- **SageMaker A2I** — Human review workflow for low-confidence extractions

## Solution Structure

```
intelligent-document-processing/
├── README.md
├── presales/                        # Business case and sales materials
│   ├── raw/                         # Source markdown files
│   ├── solution-briefing.pptx       # Executive presentation
│   ├── statement-of-work.docx       # Formal SOW
│   ├── discovery-questionnaire.xlsx
│   ├── level-of-effort-estimate.xlsx
│   └── infrastructure-costs.xlsx
├── delivery/                        # Implementation resources
│   ├── README.md
│   ├── raw/                         # Source markdown files
│   ├── detailed-design.docx         # Architecture and design
│   ├── implementation-guide.docx    # Step-by-step deployment
│   ├── configuration.xlsx           # Environment configuration reference
│   ├── project-plan.xlsx
│   └── automation/
│       └── terraform/               # Infrastructure as Code
│           ├── README.md
│           ├── environments/        # prod / test / dr
│           ├── modules/             # Reusable Terraform modules
│           └── setup/               # Backend and secrets setup
└── assets/
    └── diagrams/                    # Architecture diagrams
```

## Getting Started

### Download This Solution

**Option 1: Git Sparse Checkout (Recommended)**
```bash
git clone --filter=blob:none --sparse https://github.com/eoframework/eof-solutions.git
cd eof-solutions
git sparse-checkout set solutions/aws/ai/intelligent-document-processing
cd solutions/aws/ai/intelligent-document-processing
```

**Option 2: Browse Online**
[View on GitHub](https://github.com/eoframework/eof-solutions/tree/main/solutions/aws/ai/intelligent-document-processing)

### For Presales Teams

Navigate to **`presales/`** for customer engagement materials:

| Document | Purpose |
|----------|---------|
| `solution-briefing.pptx` | Executive presentation with business case |
| `statement-of-work.docx` | Formal project scope and terms |
| `discovery-questionnaire.xlsx` | Customer requirements gathering |
| `level-of-effort-estimate.xlsx` | Resource and cost estimation |
| `infrastructure-costs.xlsx` | Infrastructure cost breakdown |

### For Delivery Teams

Navigate to **`delivery/`** for implementation:

1. Review `implementation-guide.docx` for prerequisites and deployment steps
2. Reference `detailed-design.docx` for architecture decisions
3. Use `configuration.xlsx` for environment-specific settings
4. Deploy infrastructure via `delivery/automation/terraform/`

See [`delivery/automation/terraform/README.md`](delivery/automation/terraform/README.md) for the full Terraform deployment guide.

## Infrastructure Prerequisites

- AWS account with appropriate IAM permissions
- AWS CLI v2 configured with credentials
- Terraform 1.10+ (for infrastructure deployment)

## Use Cases

- **Invoice Processing** — Automated extraction of line items, totals, and vendor details
- **Contract Analysis** — Key clause identification and obligation extraction
- **Form Digitization** — Converting paper forms to structured data
- **Document Classification** — Automatic routing based on document type and content
- **Compliance Review** — PII detection and redaction for regulatory requirements

---

**[EO Framework](https://eoframework.org)** — Exceptional Outcome Framework
