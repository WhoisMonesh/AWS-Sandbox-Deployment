#!/usr/bin/env pwsh
# tf.ps1 - PowerShell twin of tf.sh for the KodeKloud AWS Playground lab.
#
# Usage:  .\tf.ps1 <target> <action> [extra terraform args...]
#   target : a service under services/  (e.g. ec2, s3, rds, eks)
#            or a group  (group-core, group-storage, ...)
#            or  all      (NOT recommended; hits sandbox caps)
#   action : plan | apply | destroy | init | validate  (default: plan)
#
# Example: .\tf.ps1 ec2 plan
#          .\tf.ps1 s3 apply
#          .\tf.ps1 group-core destroy

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$ServicesDir = Join-Path $Root "services"

$groups = @{
  "group-core"       = @("iam-vpc", "ec2", "s3", "rds", "lambda", "dynamodb", "eks", "ecr", "ecs")
  "group-storage"    = @("s3", "ebs", "efs")
  "group-database"   = @("rds", "dynamodb", "redshift-serverless")
  "group-network"    = @("apigateway", "route53", "waf", "elb", "service-discovery", "internet-monitor")
  "group-integration"= @("stepfunctions", "kinesis", "eventbridge", "sns", "sqs", "appmesh", "appsync", "apprunner")
  "group-security"   = @("cognito", "kms", "acm", "acm-pca")
  "group-monitor"    = @("cloudwatch", "cloudtrail", "config", "inspector", "cloudwatch-rum", "application-insights", "cloudwatch-synthetics", "cloudwatch-logs", "xray", "ssm")
  "group-devtools"   = @("codedeploy", "codeartifact")
  "group-tools"      = @("autoscaling", "app-autoscaling", "secrets-manager", "cloudformation", "directory-service", "datasync", "evidently")
}

function Usage { Write-Host "Usage: .\tf.ps1 <service|group-xxx|all> <plan|apply|destroy|init|validate> [args]"; exit 1 }

if ($args.Count -lt 1) { Usage }
$TARGET = $args[0]
$ACTION = if ($args.Count -ge 2) { $args[1] } else { "plan" }
$EXTRA  = if ($args.Count -ge 3) { $args[2..($args.Count - 1)] } else { @() }

function Resolve-Targets($t) {
  if ($t -eq "all") {
    return @(Get-ChildItem $ServicesDir -Directory | ForEach-Object { $_.Name })
  }
  if ($groups.ContainsKey($t)) { return $groups[$t] }
  if (Test-Path (Join-Path $ServicesDir $t)) { return @($t) }
  return @("UNKNOWN:$t")
}

$TARGETS = Resolve-Targets $TARGET

if ($TARGETS[0] -like "UNKNOWN:*") {
  Write-Host "Unknown target: $TARGET" -ForegroundColor Red
  Write-Host "Available services: $((Get-ChildItem $ServicesDir -Directory).Name -join ' ')"
  Write-Host "Available groups: $($groups.Keys -join ' ')"
  exit 1
}

$exitCode = 0
foreach ($svc in $TARGETS) {
  $dir = Join-Path $ServicesDir $svc
  if (-not (Test-Path $dir)) { Write-Host "Missing service dir: $dir" -ForegroundColor Red; $exitCode = 1; continue }
  Write-Host ""
  Write-Host "======================================================" -ForegroundColor Cyan
  Write-Host "  terraform $ACTION  ->  services/$svc" -ForegroundColor Cyan
  Write-Host "======================================================" -ForegroundColor Cyan
  Set-Location $dir
  try {
    & terraform init -input=false
    & terraform $ACTION @EXTRA
    if ($LASTEXITCODE -ne 0) { Write-Host "!! Failed: services/$svc" -ForegroundColor Red; $exitCode = 1 }
  } finally {
    Set-Location $Root
  }
}

exit $exitCode
