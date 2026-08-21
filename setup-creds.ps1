#!/usr/bin/env pwsh
# setup-creds.ps1 - Interactive AWS credential bootstrap for the KodeKloud AWS Playground (Windows).
#
# Mirrors setup-creds.sh: asks for account sign-in URL, IAM username, password, region,
# then tries `aws login` (browser) and falls back to long-lived IAM access keys.
# Writes a `kk-playground` profile to %USERPROFILE%\.aws\config.

$ErrorActionPreference = "Stop"
$PROFILE = "kk-playground"
$LOGIN_PROFILE = "kk-playground-login"

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "OK  $m" -ForegroundColor Green }
function Warn($m){ Write-Host "!!  $m" -ForegroundColor Yellow }

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  Write-Host "aws CLI not found. Install it first: winget install Amazon.AWSCLI" -ForegroundColor Red
  exit 1
}

# The KodeKloud playground issues a fresh account/URL/user every session, so we
# always prompt (no stale default) and re-ask until a value is provided.
do { $signinUrl = Read-Host "AWS account sign-in URL" } while ([string]::IsNullOrWhiteSpace($signinUrl))
do { $iamUser    = Read-Host "IAM username" }        while ([string]::IsNullOrWhiteSpace($iamUser))

if ($signinUrl -match "https?://(\d{12})\.signin\.aws\.amazon\.com") {
  $accountId = $Matches[1]
} else {
  $accountId = Read-Host "Could not parse account id from URL. Enter it manually"
}

$securePass = Read-Host "Console password (used only for the browser login, never stored)" -AsSecureString
# password is intentionally not persisted anywhere

$defaultRegion = "us-east-1"
$region = Read-Host "Region [$defaultRegion]"
if ($region -eq "") { $region = $defaultRegion }

$iamArn = "arn:aws:iam::${accountId}:user/${iamUser}"

# ---------------- Attempt 1: aws login ----------------
function Try-AwsLogin {
  Info "Attempting 'aws login' (browser-based console credentials)..."
  try {
    & aws login --profile $LOGIN_PROFILE --region $region 2>&1
    if ($LASTEXITCODE -eq 0) {
      Ok "aws login succeeded."
      & aws configure set "profile.$PROFILE.region" $region
      & aws configure set "profile.$PROFILE.credential_process" "aws configure export-credentials --profile $LOGIN_PROFILE --format process"
      & aws configure set "profile.$LOGIN_PROFILE.region" $region
      & aws configure set "profile.$LOGIN_PROFILE.login_session" $iamArn
      return $true
    }
  } catch {
    Warn "aws login failed."
  }
  return $false
}

# ---------------- Attempt 2: access keys ----------------
function Use-AccessKeys {
  Warn "Falling back to long-lived IAM access keys."
  Write-Host "  1) Open the IAM console 'Security credentials' page for this user."
  Write-Host "  2) Under 'Access keys' choose 'Create access key' (use case: CLI)."
  Write-Host "  3) Copy the Access key ID and Secret access key."
  $consoleUrl = "https://${region}.console.aws.amazon.com/iam/home?region=${region}#/users/${iamUser}?section=security_credentials"
  Write-Host "     $consoleUrl"
  Start-Process $consoleUrl
  $ak = Read-Host "Access Key ID"
  $sk = Read-Host "Secret Access Key"
  & aws configure unset "profile.$PROFILE.credential_process" 2>$null
  & aws configure set "profile.$PROFILE.region" $region
  & aws configure set "profile.$PROFILE.aws_access_key_id" $ak
  & aws configure set "profile.$PROFILE.aws_secret_access_key" $sk
  Ok "Stored access keys in profile '$PROFILE'."
}

# ---------------- Clear any previously stored credentials ----------------
# Re-running this script must start from a clean slate so stale access keys or
# an old credential_process never linger alongside the new credentials.
function Clear-OldCreds {
  foreach ($p in @($PROFILE, $LOGIN_PROFILE)) {
    & aws configure unset "profile.$p.aws_access_key_id" 2>$null
    & aws configure unset "profile.$p.aws_secret_access_key" 2>$null
    & aws configure unset "profile.$p.credential_process" 2>$null
  }
}
Clear-OldCreds

Write-Host "How would you like to authenticate?"
Write-Host "  1) aws login (browser)  - requires IAM perm SignInLocalDevelopmentAccess (usually ABSENT on KodeKloud lab users; gives a 400)"
Write-Host "  2) Long-lived IAM access keys  - recommended for the KodeKloud playground"
$auth = Read-Host "Choice [2]"
if ($auth -eq "") { $auth = "2" }

if ($auth -eq "1") {
  if (-not (Try-AwsLogin)) { Use-AccessKeys }
} else {
  Use-AccessKeys
}

# ---------------- Verify ----------------
Info "Verifying identity with 'aws sts get-caller-identity --profile $PROFILE'..."
& aws sts get-caller-identity --profile $PROFILE --region $region
if ($LASTEXITCODE -eq 0) {
  Ok "Credentials work. You can now run:  .\tf.ps1 <service> plan"
} else {
  Warn "Identity check failed. If you just created access keys, wait a few seconds and retry."
}
