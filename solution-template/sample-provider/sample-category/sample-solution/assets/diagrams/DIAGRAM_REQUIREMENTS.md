# Architecture Diagram Requirements

Replace this file with your solution's specific component specifications.

## Solution Name

[Solution Name] — [Provider] [Category]

## Required Components

List every service or component that must appear in the diagram.
Group by layer or account/cluster boundary.

### Layer 1: [e.g., Ingestion / Frontend / Management]
- **[Service Name]** — [purpose in this solution]
- **[Service Name]** — [purpose in this solution]

### Layer 2: [e.g., Processing / Application / Security]
- **[Service Name]** — [purpose in this solution]
- **[Service Name]** — [purpose in this solution]

### Layer 3: [e.g., Storage / Data / Workloads]
- **[Service Name]** — [purpose in this solution]
- **[Service Name]** — [purpose in this solution]

### External / On-Premises
- **[System Name]** — [how it connects to the solution]

## Data Flows

Describe the primary data flows the diagram must show:

1. [Source] → [Target] — [description of what flows]
2. [Source] → [Target] — [description of what flows]
3. [Source] → [Target] — [description of what flows]

## Cluster / Boundary Layout

List the logical groupings and their colour role:

| Cluster Name | Colour Role | Services Inside |
|--------------|-------------|-----------------|
| [Name] | management | [service1, service2] |
| [Name] | security | [service1, service2] |
| [Name] | network | [service1, service2] |
| [Name] | workload | [service1, service2] |

Available colour roles: `management`, `security`, `network`, `workload`, `identity`, `external`, `data`, `devops`
See `eof-tools/utils/diagram_utils.py` for hex values.

## Diagram Layout

- **Direction**: LR (left-to-right) or TB (top-to-bottom)
- **Recommended for pipelines**: LR
- **Recommended for hierarchies**: TB

## Export Requirements

- **Output file**: `architecture-diagram.png`
- **Resolution**: 1920x1080 minimum
- **DPI**: 300 for print quality
