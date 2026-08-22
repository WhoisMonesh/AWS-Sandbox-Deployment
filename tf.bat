@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "SERVICES_DIR=%ROOT%services"

if "%~1"=="" goto usage
set "TARGET=%~1"
set "ACTION=%~2"
if not defined ACTION set "ACTION=plan"
echo %ACTION%| findstr /r "^plan$ ^apply$ ^destroy$ ^init$ ^validate$ ^output$" >nul || (
    echo Invalid action: %ACTION%
    echo Valid actions: plan apply destroy init validate output
    echo Hint: quote comma lists, e.g. tf.bat "eks,bastion" plan
    exit /b 1
)
shift
shift
set "EXTRA="
:collect
if "%~1"=="" goto collected
set "EXTRA=%EXTRA% %~1"
shift
goto collect
:collected

set "TARGET=%TARGET:,= %"
set "TARGETS="
set "UNKNOWN="
for %%T in (%TARGET%) do call :ResolveOne %%T
if defined UNKNOWN goto unknown_target
goto resolved

:ResolveOne
set "RT=%~1"
if /i "%RT%"=="all" (
    for /d %%D in ("%SERVICES_DIR%\*") do set "TARGETS=!TARGETS! %%~nxD"
    goto :eof
)
if /i "%RT%"=="group-core" (
    set "TARGETS=!TARGETS! iam-vpc ec2 s3 rds lambda dynamodb eks ecr ecs bastion"
    goto :eof
)
if /i "%RT%"=="group-storage" (
    set "TARGETS=!TARGETS! s3 ebs efs"
    goto :eof
)
if /i "%RT%"=="group-database" (
    set "TARGETS=!TARGETS! rds dynamodb redshift-serverless"
    goto :eof
)
if /i "%RT%"=="group-network" (
    set "TARGETS=!TARGETS! apigateway route53 waf elb service-discovery internet-monitor"
    goto :eof
)
if /i "%RT%"=="group-integration" (
    set "TARGETS=!TARGETS! stepfunctions kinesis eventbridge sns sqs appmesh appsync apprunner"
    goto :eof
)
if /i "%RT%"=="group-security" (
    set "TARGETS=!TARGETS! cognito kms acm acm-pca"
    goto :eof
)
if /i "%RT%"=="group-monitor" (
    set "TARGETS=!TARGETS! cloudwatch cloudtrail config inspector cloudwatch-rum application-insights cloudwatch-synthetics cloudwatch-logs xray ssm"
    goto :eof
)
if /i "%RT%"=="group-devtools" (
    set "TARGETS=!TARGETS! codedeploy codeartifact"
    goto :eof
)
if /i "%RT%"=="group-tools" (
    set "TARGETS=!TARGETS! autoscaling app-autoscaling secrets-manager cloudformation directory-service datasync evidently"
    goto :eof
)
if exist "%SERVICES_DIR%\%RT%" (
    set "TARGETS=!TARGETS! %RT%"
    goto :eof
)
set "UNKNOWN=%UNKNOWN% %RT%"
goto :eof

:unknown_target
echo Unknown target^(s^):%UNKNOWN%
echo Available services:
dir /b /ad "%SERVICES_DIR%" 2>nul
echo Available groups: group-core group-storage group-database group-network group-integration group-security group-monitor group-devtools group-tools all
exit /b 1

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
echo Usage: tf.bat "svc[,svc2,...]|group-xxx|all" ^<plan^|apply^|destroy^|init^|validate^|output^> [args]
exit /b 1
