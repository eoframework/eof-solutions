#!/bin/bash
#------------------------------------------------------------------------------
# Azure Terraform State Backend Setup
#------------------------------------------------------------------------------
# Creates Azure resources required for Terraform remote state storage:
# - Resource Group
# - Storage Account (with versioning, encryption, TLS 1.2)
# - Blob Container
# - backend.tfvars for use with: terraform init -backend-config=backend.tfvars
#
# This script is idempotent - safe to run multiple times.
#
# Usage:
#   ./state-backend.sh [environment]
#
# Arguments:
#   environment - Required: prod, test, or dr
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - Contributor role on the target subscription
#
# Naming Convention:
#   Resource Group:  tfstate-{project_name}-{env}-rg
#   Storage Account: tfstate{project_name}{env}{suffix} (max 24 chars, no hyphens)
#   Container:       tfstate
#   State Key:       {project_name}-{env}.tfstate
#------------------------------------------------------------------------------

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse a simple top-level string value from a tfvars file
# Handles: key = "value"  or  key = value
parse_tfvar() {
    local file="$1"
    local var="$2"
    grep -E "^${var}\s*=" "$file" 2>/dev/null \
        | sed 's/.*=\s*//' \
        | tr -d '"' \
        | tr -d "'" \
        | tr -d ' ' \
        | head -1
}

# Parse region from within the azure object block: azure = { region = "eastus", ... }
parse_azure_region() {
    local file="$1"
    awk '/^azure\s*=\s*\{/,/\}/' "$file" \
        | grep -E '^\s*region\s*=' \
        | sed 's/.*=\s*"\([^"]*\)".*/\1/' \
        | head -1
}

#------------------------------------------------------------------------------
# Setup
#------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENTS_DIR="$(cd "$SCRIPT_DIR/../../environments" && pwd)"

if [ -z "$1" ]; then
    log_error "Environment required. Usage: $0 [prod|test|dr]"
    exit 1
fi

ENVIRONMENT="$1"

if [[ ! "$ENVIRONMENT" =~ ^(prod|test|dr)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Must be: prod, test, or dr"
    exit 1
fi

ENV_DIR="${ENVIRONMENTS_DIR}/${ENVIRONMENT}"
TFVARS_FILE="${ENV_DIR}/config/project.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    log_error "Configuration file not found: $TFVARS_FILE"
    log_error "Please create config/project.tfvars with required values."
    exit 1
fi

log_info "Environment : ${ENVIRONMENT}"
log_info "Config file : ${TFVARS_FILE}"

#------------------------------------------------------------------------------
# Read Configuration
#------------------------------------------------------------------------------

PROJECT_NAME=$(parse_tfvar "$TFVARS_FILE" "project_name")
REGION=$(parse_azure_region "$TFVARS_FILE")

if [ -z "$PROJECT_NAME" ]; then
    log_error "project_name not found in $TFVARS_FILE"
    exit 1
fi

if [ -z "$REGION" ]; then
    log_warn "azure.region not found in $TFVARS_FILE — defaulting to eastus"
    REGION="eastus"
fi

#------------------------------------------------------------------------------
# Generate Resource Names
#------------------------------------------------------------------------------

# Storage account: lowercase alphanumeric only, max 24 chars, globally unique
# Pattern: tfstate + project_name (up to 8) + env (up to 4) + random 4-char suffix
PROJECT_SHORT=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]' | head -c 8)
ENV_SHORT=$(echo "$ENVIRONMENT" | head -c 4)
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 4)
STORAGE_ACCOUNT_NAME="tfstate${PROJECT_SHORT}${ENV_SHORT}${SUFFIX}"

RESOURCE_GROUP_NAME="tfstate-${PROJECT_NAME}-${ENVIRONMENT}-rg"
CONTAINER_NAME="tfstate"
STATE_KEY="${PROJECT_NAME}-${ENVIRONMENT}.tfstate"

log_info "Resource Group  : ${RESOURCE_GROUP_NAME}"
log_info "Storage Account : ${STORAGE_ACCOUNT_NAME}"
log_info "Container       : ${CONTAINER_NAME}"
log_info "State Key       : ${STATE_KEY}"
log_info "Region          : ${REGION}"

#------------------------------------------------------------------------------
# Verify Azure CLI Authentication
#------------------------------------------------------------------------------

log_info "Verifying Azure CLI authentication..."
if ! az account show > /dev/null 2>&1; then
    log_error "Not authenticated. Please run: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
log_success "Subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})"

#------------------------------------------------------------------------------
# Create Resource Group
#------------------------------------------------------------------------------

log_info "Creating resource group: ${RESOURCE_GROUP_NAME}..."
if az group show --name "$RESOURCE_GROUP_NAME" > /dev/null 2>&1; then
    log_warn "Resource group already exists: ${RESOURCE_GROUP_NAME}"
else
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$REGION" \
        --tags \
            Purpose=terraform-state \
            Environment="$ENVIRONMENT" \
            Project="$PROJECT_NAME" \
            ManagedBy=state-backend-script \
        --output none
    log_success "Resource group created: ${RESOURCE_GROUP_NAME}"
fi

#------------------------------------------------------------------------------
# Create Storage Account
#------------------------------------------------------------------------------

log_info "Creating storage account: ${STORAGE_ACCOUNT_NAME}..."
if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" > /dev/null 2>&1; then
    log_warn "Storage account already exists: ${STORAGE_ACCOUNT_NAME}"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$REGION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --encryption-services blob \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --https-only true \
        --tags \
            Purpose=terraform-state \
            Environment="$ENVIRONMENT" \
            Project="$PROJECT_NAME" \
            ManagedBy=state-backend-script \
        --output none
    log_success "Storage account created: ${STORAGE_ACCOUNT_NAME}"
fi

# Enable versioning for state file history
log_info "Enabling blob versioning..."
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true \
    --output none
log_success "Blob versioning enabled"

#------------------------------------------------------------------------------
# Create Blob Container
#------------------------------------------------------------------------------

log_info "Creating blob container: ${CONTAINER_NAME}..."
if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login > /dev/null 2>&1; then
    log_warn "Container already exists: ${CONTAINER_NAME}"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --output none
    log_success "Container created: ${CONTAINER_NAME}"
fi

#------------------------------------------------------------------------------
# Write backend.tfvars
#------------------------------------------------------------------------------

BACKEND_FILE="${ENV_DIR}/backend.tfvars"
log_info "Writing backend configuration: ${BACKEND_FILE}"

cat > "$BACKEND_FILE" << EOF
#------------------------------------------------------------------------------
# Terraform Backend Configuration — Azure Storage
#------------------------------------------------------------------------------
# Generated by state-backend.sh
# Use with: terraform init -backend-config=backend.tfvars
#
# WARNING: This file is git-ignored. Do not commit it.
#------------------------------------------------------------------------------

resource_group_name  = "${RESOURCE_GROUP_NAME}"
storage_account_name = "${STORAGE_ACCOUNT_NAME}"
container_name       = "${CONTAINER_NAME}"
key                  = "${STATE_KEY}"
EOF

log_success "Backend configuration saved to: ${BACKEND_FILE}"

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

echo ""
echo "=============================================================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=============================================================================="
echo ""
echo "Backend configuration written to: ${BACKEND_FILE}"
echo ""
echo "Initialize Terraform with:"
echo -e "  ${YELLOW}cd environments/${ENVIRONMENT}${NC}"
echo -e "  ${YELLOW}./eo-deploy.sh init -backend-config=backend.tfvars${NC}"
echo "=============================================================================="
