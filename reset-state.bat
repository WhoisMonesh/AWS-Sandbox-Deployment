@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem reset-state.bat - Wipe ALL local Terraform artifacts for every service:
rem state files, provider lock files, .terraform caches, plan and crash logs.
rem WHY: KodeKloud gives a FRESH AWS account each lab session, so leftover
rem local state describes resources in a dead account - drop it and let
rem terraform treat everything as brand new.
rem USAGE: reset-state.bat [-y] [root]

set "ASSUME_YES="
set "TARGET_ROOT="
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-y" (
    set "ASSUME_YES=1"
    shift
    goto parse_args
)
set "TARGET_ROOT=%~1"
shift
goto parse_args
:args_done
if not defined TARGET_ROOT set "TARGET_ROOT=%~dp0"
if "%TARGET_ROOT:~-1%" neq "\" set "TARGET_ROOT=%TARGET_ROOT%\"

echo This will DELETE under %TARGET_ROOT%services :
echo   - .terraform\                 ^(provider/module caches^)
echo   - .terraform.lock.hcl         ^(provider lock files^)
echo   - terraform.tfstate(.backup)  ^(local state^)
echo   - terraform.tfstate.lock.info, *.tfplan, crash.log*
echo.
if defined ASSUME_YES goto confirmed
choice /c YN /m "Proceed"
if errorlevel 2 (
    echo Aborted.
    exit /b 1
)
:confirmed

set COUNT=0
for /d /r "%TARGET_ROOT%services" %%D in (.terraform) do (
    if exist "%%D" (
        rmdir /s /q "%%D"
        echo   removed %%D\
        set /a COUNT+=1
    )
)
for /r "%TARGET_ROOT%services" %%F in (.terraform.lock.hcl terraform.tfstate terraform.tfstate.backup terraform.tfstate.lock.info crash.log *.tfplan) do (
    if exist "%%F" (
        del /f /q "%%F"
        echo   removed %%F
        set /a COUNT+=1
    )
)
echo.
if %COUNT%==0 echo   Nothing to remove - already clean.
echo Done. Next: tf.bat ^<service^> plan   ^(init runs automatically^)
exit /b 0
