@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "SERVICES_DIR=%ROOT%services"

if "%~1"=="" goto usage
set "TARGET=%~1"
set "ACTION=%~2"
if not defined ACTION set "ACTION=plan"
shift
shift
set "EXTRA="
:collect
if "%~1"=="" goto collected
set "EXTRA=%EXTRA% %~1"
shift
goto collect
:collected

set "TARGETS="
if /i "%TARGET%"=="all" goto build_all
if /i "%TARGET%"=="group-core" set "TARGETS=iam-vpc ec2 s3 rds lambda dynamodb eks ecr ecs"
if /i "%TARGET%"=="group-storage" set "TARGETS=s3 ebs efs"
if /i "%TARGET%"=="group-database" set "TARGETS=rds dynamodb redshift-serverless"
if /i "%TARGET%"=="group-network" set "TARGETS=apigateway route53 waf elb service-discovery internet-monitor"
if /i "%TARGET%"=="group-integration" set "TARGETS=stepfunctions kinesis eventbridge sns sqs appmesh appsync apprunner"
if /i "%TARGET%"=="group-security" set "TARGETS=cognito kms acm acm-pca"
if /i "%TARGET%"=="group-monitor" set "TARGETS=cloudwatch cloudtrail config inspector cloudwatch-rum application-insights cloudwatch-synthetics cloudwatch-logs xray ssm"
if /i "%TARGET%"=="group-devtools" set "TARGETS=codedeploy codeartifact"
if /i "%TARGET%"=="group-tools" set "TARGETS=autoscaling app-autoscaling secrets-manager cloudformation directory-service datasync evidently"
if defined TARGETS goto resolved
if exist "%SERVICES_DIR%\%TARGET%" (
    set "TARGETS=%TARGET%"
    goto resolved
)
echo Unknown target: %TARGET%
echo Available services:
dir /b /ad "%SERVICES_DIR%" 2>nul
echo Available groups: group-core group-storage group-database group-network group-integration group-security group-monitor group-devtools group-tools all
exit /b 1

:build_all
for /d %%D in ("%SERVICES_DIR%\*") do set "TARGETS=!TARGETS! %%~nxD"
:resolved

set RC=0
for %%S in (%TARGETS%) do call :RunSvc %%S
exit /b %RC%

:RunSvc
pushd "%SERVICES_DIR%\%~1" 2>nul || (
    echo Missing service dir: %SERVICES_DIR%\%~1
    set RC=1
    exit /b 0
)
echo.
echo ======================================================
echo   terraform %ACTION%  -^>  services/%~1
echo ======================================================
terraform init -input=false
if errorlevel 1 (
    echo !! Failed init: services/%~1
    set RC=1
    popd
    exit /b 0
)
if /i "%ACTION%"=="apply" call :AutoApprove
if /i "%ACTION%"=="destroy" call :AutoApprove
terraform %ACTION%%EXTRA%
if errorlevel 1 (
    echo !! Failed: services/%~1
    set RC=1
)
popd
exit /b 0

:AutoApprove
if defined EXTRA (
    echo %EXTRA%| findstr /c:" -auto-approve" /c:" --auto-approve" >nul || set "EXTRA=%EXTRA% -auto-approve"
) else (
    set "EXTRA= -auto-approve"
)
exit /b 0

:usage
echo Usage: tf.bat ^<service^|group-xxx^|all^> ^<plan^|apply^|destroy^|init^|validate^> [args]
exit /b 1
