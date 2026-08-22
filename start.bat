@echo off
title AWS Sandbox Deployment - Windows cmd
setlocal EnableExtensions
cd /d "%~dp0"
set "AUTO_ARGS=%*"

call :CheckTool aws Amazon.AWSCLI
call :CheckTool terraform HashiCorp.Terraform
call :CheckTool jq jqlang.jq
call :CheckTool git Git.Git

echo ==^> Verifying prerequisites:
for %%C in (aws terraform jq git) do call :VerTool %%C

if exist "%~dp0setup-creds.bat" (
    echo ==^> Running interactive credential setup ^(kk-playground profile^)...
    call "%~dp0setup-creds.bat"
) else (
    echo !!   setup-creds.bat not found; run it manually.
)

if defined AUTO_ARGS call "%~dp0tf.bat" %AUTO_ARGS%
if defined AUTO_ARGS exit /b %errorlevel%

:menu
echo.
echo Available services:
dir /b /ad "%~dp0services" 2>nul
echo Groups: group-core group-storage group-database group-network group-integration group-security group-monitor group-devtools group-tools
echo.
set "TGT="
set /p "TGT=Deploy target (e.g. s3, eks, group-core, 'all', q to quit): "
if /i "%TGT%"=="q" goto bye
if not defined TGT goto bye
set "ACT=plan"
set /p "ACT=Action [plan^|apply^|destroy] (default plan): "
if not defined ACT set "ACT=plan"
call "%~dp0tf.bat" %TGT% %ACT%
goto menu

:bye
echo Bye.
pause
exit /b 0

:CheckTool
where %1 >nul 2>nul && (
    echo OK   %1 already installed
    exit /b 0
)
where winget >nul 2>nul || (
    echo !!   winget not found. Please install %2 manually.
    exit /b 0
)
echo ==^> Installing %2 via winget...
winget install --id %2 -e --accept-package-agreements --accept-source-agreements
where %1 >nul 2>nul && (
    echo OK   %1 installed
    exit /b 0
)
echo !!   %1 still not on PATH. Open a NEW terminal window and re-run start.bat ^(PATH refresh needs a new session^).
exit /b 0

:VerTool
where %1 >nul 2>nul || (
    echo !!   %1 is missing
    exit /b 0
)
for /f "delims=" %%V in ('%1 --version') do (
    echo OK   %1 -^> %%V
    exit /b 0
)
exit /b 0
