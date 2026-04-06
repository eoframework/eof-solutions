@echo off
::------------------------------------------------------------------------------
:: Azure Terraform State Backend Setup (Windows)
::------------------------------------------------------------------------------
:: Creates Azure resources required for Terraform remote state storage:
:: - Resource Group
:: - Storage Account (with encryption, TLS 1.2)
:: - Blob Container
:: - backend.tfvars for use with: terraform init -backend-config=backend.tfvars
::
:: This script is idempotent - safe to run multiple times.
::
:: Usage:
::   state-backend.bat [environment]
::
:: Arguments:
::   environment - Required: prod, test, or dr
::
:: Prerequisites:
::   - Azure CLI installed and authenticated (az login)
::   - Contributor role on the target subscription
::
:: Naming Convention:
::   Resource Group:  tfstate-{project_name}-{env}-rg
::   Storage Account: tfstate{project_name}{env}{suffix} (max 24 chars, no hyphens)
::   Container:       tfstate
::   State Key:       {project_name}-{env}.tfstate
::------------------------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "ENVIRONMENTS_DIR=%SCRIPT_DIR%\..\..\environments"

:: Check for environment argument
if "%~1"=="" (
    echo [ERROR] Environment required. Usage: %~nx0 [prod^|test^|dr]
    exit /b 1
)

set "ENVIRONMENT=%~1"

:: Validate environment
if /i not "%ENVIRONMENT%"=="prod" (
    if /i not "%ENVIRONMENT%"=="test" (
        if /i not "%ENVIRONMENT%"=="dr" (
            echo [ERROR] Invalid environment: %ENVIRONMENT%. Must be: prod, test, or dr
            exit /b 1
        )
    )
)

set "ENV_DIR=%ENVIRONMENTS_DIR%\%ENVIRONMENT%"
set "TFVARS_FILE=%ENV_DIR%\config\project.tfvars"

if not exist "%TFVARS_FILE%" (
    echo [ERROR] Configuration file not found: %TFVARS_FILE%
    echo [ERROR] Please create config\project.tfvars with required values.
    exit /b 1
)

echo [INFO] Environment : %ENVIRONMENT%
echo [INFO] Config file : %TFVARS_FILE%

:: Parse project_name from tfvars
for /f "tokens=1,* delims==" %%a in ('findstr /r "^project_name" "%TFVARS_FILE%"') do (
    set "PROJECT_NAME=%%b"
)
set "PROJECT_NAME=!PROJECT_NAME: =!"
set "PROJECT_NAME=!PROJECT_NAME:"=!"

:: Parse region from azure object block (looks for "region =" inside azure = { ... })
set "REGION="
set "IN_AZURE_BLOCK=0"
for /f "tokens=*" %%l in (%TFVARS_FILE%) do (
    set "LINE=%%l"
    echo !LINE! | findstr /r "^azure\s*=" >nul 2>&1 && set "IN_AZURE_BLOCK=1"
    if "!IN_AZURE_BLOCK!"=="1" (
        echo !LINE! | findstr /r "region\s*=" >nul 2>&1 && (
            for /f "tokens=2 delims==" %%v in ("!LINE!") do (
                set "REGION=%%v"
                set "REGION=!REGION: =!"
                set "REGION=!REGION:"=!"
                set "REGION=!REGION:,=!"
            )
            set "IN_AZURE_BLOCK=0"
        )
    )
)

if "!PROJECT_NAME!"=="" (
    echo [ERROR] project_name not found in %TFVARS_FILE%
    exit /b 1
)

if "!REGION!"=="" (
    echo [WARN] azure.region not found in %TFVARS_FILE% - defaulting to eastus
    set "REGION=eastus"
)

:: Generate storage account name (lowercase alphanumeric, max 24 chars)
:: Pattern: tfstate + project (up to 8) + env (up to 4) + 4 random chars
set "PROJECT_SHORT=!PROJECT_NAME:~0,8!"
:: Convert to lowercase (basic approach)
for %%c in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "PROJECT_SHORT=!PROJECT_SHORT:%%c=%%c!"
)

:: Generate 4-char random suffix from timestamp
set "RND_SEED=%TIME: =0%"
set "SUFFIX=!RND_SEED:~0,2!!RND_SEED:~3,2!"
set "SUFFIX=!SUFFIX::=!"
set "SUFFIX=!SUFFIX:.=!"
:: Pad if needed and take 4 chars
set "SUFFIX=!SUFFIX!0000"
set "SUFFIX=!SUFFIX:~0,4!"

:: Lowercase the suffix
set "SUFFIX_LC=!SUFFIX!"
for %%c in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "SUFFIX_LC=!SUFFIX_LC:%%c=%%c!"
)

set "STORAGE_ACCOUNT_NAME=tfstate!PROJECT_SHORT!!ENVIRONMENT:~0,4!!SUFFIX_LC!"
:: Ensure max 24 chars
set "STORAGE_ACCOUNT_NAME=!STORAGE_ACCOUNT_NAME:~0,24!"

set "RESOURCE_GROUP_NAME=tfstate-!PROJECT_NAME!-%ENVIRONMENT%-rg"
set "CONTAINER_NAME=tfstate"
set "STATE_KEY=!PROJECT_NAME!-%ENVIRONMENT%.tfstate"

echo [INFO] Resource Group  : !RESOURCE_GROUP_NAME!
echo [INFO] Storage Account : !STORAGE_ACCOUNT_NAME!
echo [INFO] Container       : !CONTAINER_NAME!
echo [INFO] State Key       : !STATE_KEY!
echo [INFO] Region          : !REGION!

:: Verify Azure CLI authentication
echo [INFO] Verifying Azure CLI authentication...
az account show >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Not authenticated. Please run: az login
    exit /b 1
)

for /f "tokens=*" %%a in ('az account show --query id -o tsv') do set "SUBSCRIPTION_ID=%%a"
for /f "tokens=*" %%a in ('az account show --query name -o tsv') do set "SUBSCRIPTION_NAME=%%a"
echo [SUCCESS] Subscription: !SUBSCRIPTION_NAME! (!SUBSCRIPTION_ID!)

:: Create Resource Group
echo [INFO] Creating resource group: !RESOURCE_GROUP_NAME!...
az group show --name "!RESOURCE_GROUP_NAME!" >nul 2>&1
if not errorlevel 1 (
    echo [WARN] Resource group already exists: !RESOURCE_GROUP_NAME!
) else (
    az group create ^
        --name "!RESOURCE_GROUP_NAME!" ^
        --location "!REGION!" ^
        --tags Purpose=terraform-state Environment=%ENVIRONMENT% Project=!PROJECT_NAME! ManagedBy=state-backend-script ^
        --output none
    echo [SUCCESS] Resource group created: !RESOURCE_GROUP_NAME!
)

:: Create Storage Account
echo [INFO] Creating storage account: !STORAGE_ACCOUNT_NAME!...
az storage account show --name "!STORAGE_ACCOUNT_NAME!" --resource-group "!RESOURCE_GROUP_NAME!" >nul 2>&1
if not errorlevel 1 (
    echo [WARN] Storage account already exists: !STORAGE_ACCOUNT_NAME!
) else (
    az storage account create ^
        --name "!STORAGE_ACCOUNT_NAME!" ^
        --resource-group "!RESOURCE_GROUP_NAME!" ^
        --location "!REGION!" ^
        --sku Standard_LRS ^
        --kind StorageV2 ^
        --access-tier Hot ^
        --encryption-services blob ^
        --min-tls-version TLS1_2 ^
        --allow-blob-public-access false ^
        --https-only true ^
        --tags Purpose=terraform-state Environment=%ENVIRONMENT% Project=!PROJECT_NAME! ManagedBy=state-backend-script ^
        --output none
    echo [SUCCESS] Storage account created: !STORAGE_ACCOUNT_NAME!
)

:: Enable blob versioning
echo [INFO] Enabling blob versioning...
az storage account blob-service-properties update ^
    --account-name "!STORAGE_ACCOUNT_NAME!" ^
    --resource-group "!RESOURCE_GROUP_NAME!" ^
    --enable-versioning true ^
    --output none
echo [SUCCESS] Blob versioning enabled

:: Create Blob Container
echo [INFO] Creating blob container: !CONTAINER_NAME!...
az storage container show ^
    --name "!CONTAINER_NAME!" ^
    --account-name "!STORAGE_ACCOUNT_NAME!" ^
    --auth-mode login >nul 2>&1
if not errorlevel 1 (
    echo [WARN] Container already exists: !CONTAINER_NAME!
) else (
    az storage container create ^
        --name "!CONTAINER_NAME!" ^
        --account-name "!STORAGE_ACCOUNT_NAME!" ^
        --auth-mode login ^
        --output none
    echo [SUCCESS] Container created: !CONTAINER_NAME!
)

:: Write backend.tfvars
set "BACKEND_FILE=%ENV_DIR%\backend.tfvars"
echo [INFO] Writing backend configuration: !BACKEND_FILE!

(
echo #------------------------------------------------------------------------------
echo # Terraform Backend Configuration — Azure Storage
echo #------------------------------------------------------------------------------
echo # Generated by state-backend.bat
echo # Use with: terraform init -backend-config=backend.tfvars
echo #
echo # WARNING: This file is git-ignored. Do not commit it.
echo #------------------------------------------------------------------------------
echo.
echo resource_group_name  = "!RESOURCE_GROUP_NAME!"
echo storage_account_name = "!STORAGE_ACCOUNT_NAME!"
echo container_name       = "!CONTAINER_NAME!"
echo key                  = "!STATE_KEY!"
) > "!BACKEND_FILE!"

echo [SUCCESS] Backend configuration saved to: !BACKEND_FILE!

echo.
echo ==============================================================================
echo [SUCCESS] Setup Complete!
echo ==============================================================================
echo.
echo Backend configuration written to: !BACKEND_FILE!
echo.
echo Initialize Terraform with:
echo   cd environments\%ENVIRONMENT%
echo   eo-deploy.bat init -backend-config=backend.tfvars
echo ==============================================================================

endlocal
