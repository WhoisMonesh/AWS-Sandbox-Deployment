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

# Windows PowerShell 5.1 turns every native-command stderr line into an
# ErrorRecord, which is fatal when $ErrorActionPreference is "Stop".
# aws prints benign notes on stderr (e.g. `configure unset` on missing keys),
# so every aws invocation must go through this wrapper.
function Invoke-Aws {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & aws @args 2>&1 | ForEach-Object {
      if ($_ -is [System.Management.Automation.ErrorRecord]) { [string]$_.TargetObject } else { [string]$_ }
    }
  } finally {
    $ErrorActionPreference = $prev
  }
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  Write-Host "aws CLI not found. Install it first: winget install Amazon.AWSCLI" -ForegroundColor Red
  exit 1
}

# The KodeKloud playground issues a fresh account/URL/user every session, so we
# always prompt (no stale default) and re-ask until a value is provided.
$signinUrl = $env:KK_SIGNIN_URL
$tries = 0
while ([string]::IsNullOrWhiteSpace($signinUrl)) {
  $tries++
  if ($tries -gt 3) { Warn "No input detected. For non-interactive use set KK_SIGNIN_URL / KK_IAM_USER / KK_ACCESS_KEY_ID / KK_SECRET_ACCESS_KEY."; exit 1 }
  $signinUrl = Read-Host "AWS account sign-in URL"
}
$iamUser = $env:KK_IAM_USER
$tries = 0
while ([string]::IsNullOrWhiteSpace($iamUser)) {
  $tries++
  if ($tries -gt 3) { Warn "No input detected. For non-interactive use set KK_SIGNIN_URL / KK_IAM_USER / KK_ACCESS_KEY_ID / KK_SECRET_ACCESS_KEY."; exit 1 }
  $iamUser = Read-Host "IAM username"
}

if ($signinUrl -match "https?://(\d{12})\.signin\.aws\.amazon\.com") {
  $accountId = $Matches[1]
} else {
  $accountId = Read-Host "Could not parse account id from URL. Enter it manually"
}

$askPass = $true
if ($env:KK_ACCESS_KEY_ID -and $env:KK_SECRET_ACCESS_KEY) { $askPass = $false }
if ($env:KK_AUTH -eq "1") { $askPass = $true }
$securePass = $null
if ($askPass) {
  $securePass = Read-Host "Console password (used only for the browser login, never stored)" -AsSecureString
}
# password is intentionally not persisted anywhere

$defaultRegion = "us-east-1"
$region = $env:KK_REGION
if ([string]::IsNullOrWhiteSpace($region)) { $region = Read-Host "Region [$defaultRegion]" }
if ($region -eq "") { $region = $defaultRegion }

$iamArn = "arn:aws:iam::${accountId}:user/${iamUser}"

# ---------------- Attempt 1: aws login ----------------
function Try-AwsLogin {
  Info "Attempting 'aws login' (browser-based console credentials)..."
  Invoke-Aws login --profile $LOGIN_PROFILE --region $region
  if ($LASTEXITCODE -eq 0) {
    Ok "aws login succeeded."
    Invoke-Aws configure set "profile.$PROFILE.region" $region
    Invoke-Aws configure set "profile.$PROFILE.credential_process" "aws configure export-credentials --profile $LOGIN_PROFILE --format process"
    Invoke-Aws configure set "profile.$LOGIN_PROFILE.region" $region
    Invoke-Aws configure set "profile.$LOGIN_PROFILE.login_session" $iamArn
    return $true
  }
  Warn "'aws login' failed (exit code $LASTEXITCODE)."
  return $false
}

# ---------------- Attempt 2: access keys ----------------
function Use-AccessKeys {
  Warn "Falling back to long-lived IAM access keys."
  $ak = $env:KK_ACCESS_KEY_ID
  $sk = $env:KK_SECRET_ACCESS_KEY
  if (-not $ak -or -not $sk) {
    Write-Host "  1) Open the IAM console 'Security credentials' page for this user."
    Write-Host "  2) Under 'Access keys' choose 'Create access key' (use case: CLI)."
    Write-Host "  3) Copy the Access key ID and Secret access key."
    $consoleUrl = "https://${region}.console.aws.amazon.com/iam/home?region=${region}#/users/${iamUser}?section=security_credentials"
    Write-Host "     $consoleUrl"
    Start-Process $consoleUrl
    if (-not $ak) { $ak = Read-Host "Access Key ID" }
    if (-not $sk) { $sk = Read-Host "Secret Access Key" }
  }
  Invoke-Aws configure set "profile.$PROFILE.region" $region
  Invoke-Aws configure set "profile.$PROFILE.aws_access_key_id" $ak
  Invoke-Aws configure set "profile.$PROFILE.aws_secret_access_key" $sk
  Ok "Stored access keys in profile '$PROFILE'."
}

# ---------------- Clear any previously stored credentials ----------------
# Re-running this script must start from a clean slate so stale access keys or
# an old credential_process never linger alongside the new credentials.
function Clear-OldCreds {
  $credKeys = "^\s*(aws_access_key_id|aws_secret_access_key|credential_process)\s*="
  $config = Join-Path $env:USERPROFILE ".aws\config"
  if (Test-Path $config) {
    $names = @("profile $PROFILE", "profile $LOGIN_PROFILE")
    $inTarget = $false
    $new = foreach ($line in (Get-Content $config)) {
      if ($line -match "^\s*\[(.+)\]\s*$") { $inTarget = ($names -contains $Matches[1].Trim()) }
      elseif ($inTarget -and $line -match $credKeys) { continue }
      $line
    }
    Set-Content -Path $config -Value $new -Encoding ASCII
  }
  $credsFile = Join-Path $env:USERPROFILE ".aws\credentials"
  if (Test-Path $credsFile) {
    $names = @($PROFILE, $LOGIN_PROFILE)
    $inTarget = $false
    $new = foreach ($line in (Get-Content $credsFile)) {
      if ($line -match "^\s*\[(.+)\]\s*$") { $inTarget = ($names -contains $Matches[1].Trim()) }
      elseif ($inTarget -and $line -match $credKeys) { continue }
      $line
    }
    Set-Content -Path $credsFile -Value $new -Encoding ASCII
  }
}
Clear-OldCreds

$auth = $env:KK_AUTH
if (-not $auth) {
  Write-Host "How would you like to authenticate?"
  Write-Host "  1) aws login (browser)  - requires IAM perm SignInLocalDevelopmentAccess (usually ABSENT on KodeKloud lab users; gives a 400)"
  Write-Host "  2) Long-lived IAM access keys  - recommended for the KodeKloud playground"
  $auth = Read-Host "Choice [2]"
}
if ($auth -eq "") { $auth = "2" }
if ($auth -ne "1") { $auth = "2" }

if ($auth -eq "1") {
  if (-not (Try-AwsLogin)) { Use-AccessKeys }
} else {
  Use-AccessKeys
}

# ---------------- Verify ----------------
Info "Verifying identity with 'aws sts get-caller-identity --profile $PROFILE'..."
Invoke-Aws sts get-caller-identity --profile $PROFILE --region $region
if ($LASTEXITCODE -eq 0) {
  Ok "Credentials work. You can now run:  .\tf.ps1 <service> plan"
} else {
  Warn "Identity check failed. If you just created access keys, wait a few seconds and retry."
}
