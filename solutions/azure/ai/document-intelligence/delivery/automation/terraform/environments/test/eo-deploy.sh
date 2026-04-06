#!/bin/bash
#------------------------------------------------------------------------------
# Azure Document Intelligence - Test Environment
# Terraform Deployment Script
#
# Usage: ./eo-deploy.sh <command> [options]
# All config/*.tfvars files are loaded automatically, including credentials.tfvars
#------------------------------------------------------------------------------

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT=$(basename "$SCRIPT_DIR")

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  EO Framework - Azure Document Intelligence        ║${NC}"
echo -e "${BLUE}║  Environment : ${ENVIRONMENT}                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

cd "$SCRIPT_DIR"

# ─── Build -var-file arguments from config/*.tfvars (loaded alphabetically) ──
build_var_files() {
    VAR_FILES=""
    if [ -d "config" ]; then
        echo -e "${YELLOW}  Loading configuration files:${NC}"
        for file in config/*.tfvars; do
            if [ -f "$file" ]; then
                VAR_FILES="$VAR_FILES -var-file=$file"
                echo -e "${GREEN}    ✓ $file${NC}"
            fi
        done
        echo ""
    else
        echo -e "${RED}  ERROR: config/ directory not found${NC}"
        exit 1
    fi
}

show_usage() {
    echo -e "${CYAN}Usage: $0 <command> [options]${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}init${NC}       Initialize Terraform and download providers"
    echo -e "  ${GREEN}plan${NC}       Show planned infrastructure changes"
    echo -e "  ${GREEN}apply${NC}      Apply infrastructure changes"
    echo -e "  ${GREEN}destroy${NC}    Destroy infrastructure"
    echo -e "  ${GREEN}validate${NC}   Validate Terraform configuration"
    echo -e "  ${GREEN}fmt${NC}        Format Terraform files"
    echo -e "  ${GREEN}output${NC}     Show Terraform outputs"
    echo -e "  ${GREEN}show${NC}       Show current state or a saved plan"
    echo -e "  ${GREEN}state${NC}      Advanced state management"
    echo -e "  ${GREEN}refresh${NC}    Update state to match remote resources"
    echo -e "  ${GREEN}version${NC}    Show Terraform version"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${CYAN}$0 init${NC}"
    echo -e "  ${CYAN}$0 plan${NC}"
    echo -e "  ${CYAN}$0 apply -auto-approve${NC}"
    echo -e "  ${CYAN}$0 destroy${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} Ensure config/credentials.tfvars exists before running plan/apply."
    echo -e "      Copy config/credentials.tfvars.example and populate with real values."
}

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1
shift

case $COMMAND in
    "init")
        echo -e "${BLUE}  Initializing Terraform...${NC}"
        terraform init "$@"
        ;;
    "plan")
        echo -e "${BLUE}  Creating execution plan...${NC}"
        build_var_files
        terraform plan $VAR_FILES "$@"
        ;;
    "apply")
        echo -e "${BLUE}  Applying Terraform configuration...${NC}"
        build_var_files
        terraform apply $VAR_FILES "$@"
        ;;
    "destroy")
        echo -e "${RED}  Destroying infrastructure...${NC}"
        echo -e "${YELLOW}  WARNING: This will destroy all ${ENVIRONMENT} resources!${NC}"
        echo ""
        build_var_files
        terraform destroy $VAR_FILES "$@"
        ;;
    "validate")
        echo -e "${BLUE}  Validating configuration...${NC}"
        terraform validate "$@"
        ;;
    "fmt")
        echo -e "${BLUE}  Formatting Terraform files...${NC}"
        terraform fmt "$@"
        ;;
    "output")
        echo -e "${BLUE}  Showing outputs...${NC}"
        terraform output "$@"
        ;;
    "show")
        echo -e "${BLUE}  Showing current state...${NC}"
        terraform show "$@"
        ;;
    "state")
        echo -e "${BLUE}  State management...${NC}"
        terraform state "$@"
        ;;
    "refresh")
        echo -e "${BLUE}  Refreshing state...${NC}"
        build_var_files
        terraform refresh $VAR_FILES "$@"
        ;;
    "version")
        terraform version
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo -e "${RED}  Unknown command: $COMMAND${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}─────────────────────────────────────────────────────${NC}"
echo -e "${GREEN}  Done.${NC}"
