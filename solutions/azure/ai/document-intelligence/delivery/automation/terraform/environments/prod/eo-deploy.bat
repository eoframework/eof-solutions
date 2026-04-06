@echo off
::------------------------------------------------------------------------------
:: Azure Document Intelligence - Production Environment
:: Terraform Deployment Script
::
:: Usage: eo-deploy.bat <command> [options]
:: All config\*.tfvars files are loaded automatically, including credentials.tfvars
::------------------------------------------------------------------------------

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "ENVIRONMENT=Production"

echo.
echo  +===================================================+
echo  ^|  EO Framework - Azure Document Intelligence       ^|
echo  ^|  Environment : %ENVIRONMENT%                      ^|
echo  +===================================================+
echo.

cd /d "%SCRIPT_DIR%"

if "%~1"=="" (
    call :show_usage
    exit /b 1
)

set "COMMAND=%~1"
shift

:: Pass remaining args
set "EXTRA_ARGS="
:collect_args
if "%~1"=="" goto done_args
set "EXTRA_ARGS=%EXTRA_ARGS% %~1"
shift
goto collect_args
:done_args

if /i "%COMMAND%"=="init"     goto cmd_init
if /i "%COMMAND%"=="plan"     goto cmd_plan
if /i "%COMMAND%"=="apply"    goto cmd_apply
if /i "%COMMAND%"=="destroy"  goto cmd_destroy
if /i "%COMMAND%"=="validate" goto cmd_validate
if /i "%COMMAND%"=="fmt"      goto cmd_fmt
if /i "%COMMAND%"=="output"   goto cmd_output
if /i "%COMMAND%"=="show"     goto cmd_show
if /i "%COMMAND%"=="state"    goto cmd_state
if /i "%COMMAND%"=="refresh"  goto cmd_refresh
if /i "%COMMAND%"=="version"  goto cmd_version
if /i "%COMMAND%"=="help"     goto cmd_help
if /i "%COMMAND%"=="-h"       goto cmd_help
if /i "%COMMAND%"=="--help"   goto cmd_help

echo   ERROR: Unknown command: %COMMAND%
echo.
call :show_usage
exit /b 1

:cmd_init
echo   Initializing Terraform...
terraform init %EXTRA_ARGS%
goto done

:cmd_plan
echo   Creating execution plan...
call :build_var_files
terraform plan %VAR_FILES% %EXTRA_ARGS%
goto done

:cmd_apply
echo   Applying Terraform configuration...
call :build_var_files
terraform apply %VAR_FILES% %EXTRA_ARGS%
goto done

:cmd_destroy
echo   Destroying infrastructure...
echo   WARNING: This will destroy all %ENVIRONMENT% resources!
echo.
call :build_var_files
terraform destroy %VAR_FILES% %EXTRA_ARGS%
goto done

:cmd_validate
echo   Validating configuration...
terraform validate %EXTRA_ARGS%
goto done

:cmd_fmt
echo   Formatting Terraform files...
terraform fmt %EXTRA_ARGS%
goto done

:cmd_output
echo   Showing outputs...
terraform output %EXTRA_ARGS%
goto done

:cmd_show
echo   Showing current state...
terraform show %EXTRA_ARGS%
goto done

:cmd_state
echo   State management...
terraform state %EXTRA_ARGS%
goto done

:cmd_refresh
echo   Refreshing state...
call :build_var_files
terraform refresh %VAR_FILES% %EXTRA_ARGS%
goto done

:cmd_version
terraform version
goto done

:cmd_help
call :show_usage
goto done

:build_var_files
set "VAR_FILES="
if not exist "config" (
    echo   ERROR: config\ directory not found
    exit /b 1
)
echo   Loading configuration files:
for %%f in (config\*.tfvars) do (
    if exist "%%f" (
        set "VAR_FILES=!VAR_FILES! -var-file=%%f"
        echo     + %%f
    )
)
echo.
exit /b 0

:show_usage
echo   Usage: %~nx0 ^<command^> [options]
echo.
echo   Commands:
echo     init       Initialize Terraform and download providers
echo     plan       Show planned infrastructure changes
echo     apply      Apply infrastructure changes
echo     destroy    Destroy infrastructure
echo     validate   Validate Terraform configuration
echo     fmt        Format Terraform files
echo     output     Show Terraform outputs
echo     show       Show current state or a saved plan
echo     state      Advanced state management
echo     refresh    Update state to match remote resources
echo     version    Show Terraform version
echo.
echo   Examples:
echo     %~nx0 init
echo     %~nx0 plan
echo     %~nx0 apply -auto-approve
echo     %~nx0 destroy
echo.
echo   Note: Ensure config\credentials.tfvars exists before running plan/apply.
echo         Copy config\credentials.tfvars.example and populate with real values.
exit /b 0

:done
echo.
echo  -----------------------------------------------------
echo    Done.
endlocal
