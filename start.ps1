#!/usr/bin/env pwsh
# start.ps1 - KodeKloud AWS Playground bootstrap for native Windows (PowerShell).
#
# What it does:
#   1. Installs core prerequisites via winget: aws-cli v2, terraform, jq, git, unzip.
#   2. Runs setup-creds.ps1 to configure the `kk-playground` AWS profile
#      (interactive: account URL / IAM user / password + `aws login` or access keys).
#   3. Presents a menu to deploy sandbox services one at a time (via tf.ps1),
#      respecting the playground's per-account resource caps.
#
# Usage:  .\start.ps1   (run from the repo root)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
Set-Location $Root

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "OK  $m" -ForegroundColor Green }
function Warn($m){ Write-Host "!!  $m" -ForegroundColor Yellow }

# ---------------- Prerequisite installation ----------------
function Install-Prereqs {
  $needed = [ordered]@{
    "Amazon.AWSCLI"        = "aws"
    "HashiCorp.Terraform"  = "terraform"
    "jqlang.jq"            = "jq"
    "Git.Git"              = "git"
  }
  foreach ($id in $needed.Keys) {
    $cmd = $needed[$id]
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
      Ok "$cmd already installed"
      continue
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
      Warn "winget not found. Please install '$cmd' manually (terraform: https://developer.hashicorp.com/terraform/downloads)."
      continue
    }
    Info "Installing $id via winget..."
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      & winget install --id $id -e --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { [string]$_.TargetObject } else { [string]$_ }
      }
      if ($LASTEXITCODE -ne 0) { Warn "winget could not install $id (exit code $LASTEXITCODE); install '$cmd' manually if needed." }
    } finally {
      $ErrorActionPreference = $prev
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { Ok "$cmd installed" }
    else { Warn "$cmd still not on PATH after winget; open a new terminal or install it manually." }
  }
}

Install-Prereqs

Info "Verifying prerequisites:"
foreach ($c in @("aws", "terraform", "jq", "git")) {
  if (Get-Command $c -ErrorAction SilentlyContinue) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { $v = (& $c --version 2>&1 | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { [string]$_.TargetObject } else { [string]$_ } } | Select-Object -First 1) } finally { $ErrorActionPreference = $prev }
    Ok "$c -> $v"
  } else { Warn "$c is missing" }
}

# ---------------- Credential bootstrap ----------------
if (Test-Path setup-creds.ps1) {
  Info "Running interactive credential setup (kk-playground profile)..."
  & "$Root\setup-creds.ps1"
} else {
  Warn "setup-creds.ps1 not found; run it manually."
}

# ---------------- Deploy menu ----------------
function Deploy-Menu {
  while ($true) {
    Write-Host ""
    Write-Host "Available services: $((Get-ChildItem services -Directory).Name -join ' ')"
    Write-Host "Groups: group-core group-storage group-database group-network group-integration group-security group-monitor group-devtools group-tools"
    $tgt = Read-Host "Deploy target (e.g. s3, eks, group-core, 'all', q to quit)"
    if ($tgt -eq "q" -or $tgt -eq "") { Write-Host "Bye."; break }
    $act = Read-Host "Action [plan|apply|destroy] (default plan)"
    if ($act -eq "") { $act = "plan" }
    & "$Root\tf.ps1" "$tgt" "$act"
  }
}

if ($args.Count -ge 1) {
  & "$Root\tf.ps1" @args
  exit $LASTEXITCODE
}

Deploy-Menu
