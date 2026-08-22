@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROFILE_NAME=kk-playground"
set "LOGIN_PROFILE=kk-playground-login"

where aws >nul 2>nul || (
    echo aws CLI not found. Install it first: winget install Amazon.AWSCLI
    exit /b 1
)

echo KodeKloud AWS Playground - credential setup
echo.

:ask_url
set "SIGNIN_URL="
set /p "SIGNIN_URL=AWS account sign-in URL: "
if not defined SIGNIN_URL goto ask_url

:ask_user
set "IAM_USER="
set /p "IAM_USER=IAM username: "
if not defined IAM_USER goto ask_user

set "ACCOUNT_ID="
set "URLTMP=%SIGNIN_URL:http://=%"
set "URLTMP=%URLTMP:https://=%"
for /f "tokens=1 delims=." %%a in ("%URLTMP%") do set "CANDIDATE=%%a"
if defined CANDIDATE echo %CANDIDATE%| findstr /r "^[0-9][0-9]*$" >nul && set "ACCOUNT_ID=%CANDIDATE%"
if not defined ACCOUNT_ID set /p "ACCOUNT_ID=Could not parse account id from URL. Enter it manually: "

set "CONSOLE_PASS="
set /p "CONSOLE_PASS=Console password (visible in cmd; used only for browser login, never stored): "

set "REGION=us-east-1"
set /p "REGION=Region [us-east-1]: "

echo.
echo ==^> Account ID : %ACCOUNT_ID%
echo ==^> IAM user   : %IAM_USER%
echo ==^> Region     : %REGION%
echo.

call :ClearOldCreds

echo How would you like to authenticate?
echo   1) aws login (browser)  - requires IAM perm SignInLocalDevelopmentAccess (usually ABSENT on KodeKloud lab users)
echo   2) Long-lived IAM access keys  - recommended for the KodeKloud playground
set "AUTH=2"
set /p "AUTH=Choice [2]: "

if "%AUTH%"=="1" (
    call :TryAwsLogin
    if errorlevel 1 call :UseAccessKeys
) else (
    call :UseAccessKeys
)

echo ==^> Verifying identity with 'aws sts get-caller-identity --profile %PROFILE_NAME%'...
aws sts get-caller-identity --profile %PROFILE_NAME% --region %REGION%
if errorlevel 1 (
    echo !!  Identity check failed. If you just created access keys, wait a few seconds and retry.
) else (
    echo OK   Credentials work. You can now run:  tf.bat ^<service^> plan
)
exit /b 0

:TryAwsLogin
echo ==^> Attempting 'aws login' (browser-based console credentials)...
aws login --profile %LOGIN_PROFILE% --region %REGION%
if errorlevel 1 (
    echo !!  'aws login' failed ^(exit code !errorlevel!^).
    exit /b 1
)
echo OK   aws login succeeded.
aws configure set profile.%PROFILE_NAME%.region %REGION%
aws configure set profile.%PROFILE_NAME%.credential_process "aws configure export-credentials --profile %LOGIN_PROFILE% --format process"
aws configure set profile.%LOGIN_PROFILE%.region %REGION%
aws configure set profile.%LOGIN_PROFILE%.login_session arn:aws:iam::%ACCOUNT_ID%:user/%IAM_USER%
exit /b 0

:UseAccessKeys
echo !!  Falling back to long-lived IAM access keys.
echo   1) Open the IAM console 'Security credentials' page for this user.
echo   2) Under 'Access keys' choose 'Create access key' (use case: CLI).
echo   3) Copy the Access key ID and Secret access key.
set "CREDS_URL=https://%REGION%.console.aws.amazon.com/iam/home?region=%REGION%#/users/%IAM_USER%?section=security_credentials"
echo     %CREDS_URL%
start "" "%CREDS_URL%"
set "AK="
set "SK="
set /p "AK=Access Key ID: "
set /p "SK=Secret Access Key: "
aws configure set profile.%PROFILE_NAME%.region %REGION%
aws configure set profile.%PROFILE_NAME%.aws_access_key_id "%AK%"
aws configure set profile.%PROFILE_NAME%.aws_secret_access_key "%SK%"
echo OK   Stored access keys in profile '%PROFILE_NAME%'.
exit /b 0

:ClearOldCreds
call :SanitizeAwsFile "%USERPROFILE%\.aws\config" "profile %PROFILE_NAME%"
call :SanitizeAwsFile "%USERPROFILE%\.aws\config" "profile %LOGIN_PROFILE%"
call :SanitizeAwsFile "%USERPROFILE%\.aws\credentials" "%PROFILE_NAME%"
call :SanitizeAwsFile "%USERPROFILE%\.aws\credentials" "%LOGIN_PROFILE%"
exit /b 0

:SanitizeAwsFile
set "SAF_FILE=%~1"
set "SAF_SEC=%~2"
if not exist "%SAF_FILE%" exit /b 0
set "SAF_IN=0"
(for /f "usebackq delims=" %%L in ("%SAF_FILE%") do (
    set "SAF_LINE=%%L"
    if "!SAF_LINE:~0,1!"=="[" (
        for /f "tokens=1,* delims=[]" %%a in ("!SAF_LINE!") do set "SAF_NAME=%%a"
        set "SAF_IN=0"
        if /i "!SAF_NAME!"=="%SAF_SEC%" set "SAF_IN=1"
    )
    set "SAF_EMIT=1"
    if "!SAF_IN!"=="1" echo(!SAF_LINE!| findstr /r /c:"^ *aws_access_key_id *=" /c:"^ *aws_secret_access_key *=" /c:"^ *credential_process *=" >nul && set "SAF_EMIT=0"
    if "!SAF_EMIT!"=="1" echo(!SAF_LINE!
)) > "%SAF_FILE%.tmp"
move /y "%SAF_FILE%.tmp" "%SAF_FILE%" >nul
exit /b 0
