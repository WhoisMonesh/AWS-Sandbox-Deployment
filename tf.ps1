#!/usr/bin/env pwsh
# tf.ps1 - PowerShell twin of tf.sh for the KodeKloud AWS Playground lab.
#
# Usage:  .\tf.ps1 "<target[,target2,...]>" <action> [extra terraform args...]
#   target : a service under services/  (e.g. ec2, s3, rds, eks)
#            or a group  (group-core, group-storage, ...)
#            or a comma-separated list  (e.g. "eks,bastion")
#            or  all      (NOT recommended; hits sandbox caps)
#   action : plan | apply | destroy | init | validate | output   (default: plan)
#
# Example: .\tf.ps1 ec2 plan
#          .\tf.ps1 s3 apply
#          .\tf.ps1 "eks,bastion" apply
#          .\tf.ps1 group-core destroy

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$ServicesDir = Join-Path $Root "services"

$groups = @{
  "group-core"       = @("iam-vpc", "ec2", "s3", "rds", "lambda", "dynamodb", "eks", "ecr", "ecs", "bastion")
  "group-storage"    = @("s3", "ebs", "efs")
  "group-database"   = @("rds", "dynamodb", "redshift-serverless")
  "group-network"    = @("apigateway", "route53", "waf", "elb", "service-discovery", "internet-monitor")
  "group-integration"= @("stepfunctions", "kinesis", "eventbridge", "sns", "sqs", "appmesh", "appsync", "apprunner")
  "group-security"   = @("cognito", "kms", "acm", "acm-pca")
  "group-monitor"    = @("cloudwatch", "cloudtrail", "config", "inspector", "cloudwatch-rum", "application-insights", "cloudwatch-synthetics", "cloudwatch-logs", "xray", "ssm")
  "group-devtools"   = @("codedeploy", "codeartifact")
  "group-tools"      = @("autoscaling", "app-autoscaling", "secrets-manager", "cloudformation", "directory-service", "datasync", "evidently")
}

function Usage { Write-Host 'Usage: .\tf.ps1 "<svc[,svc2,...]|group-xxx|all>" <plan|apply|destroy|init|validate|output> [args]'; exit 1 }

if ($args.Count -lt 1) { Usage }
$ACTION = if ($args.Count -ge 2) { $args[1] } else { "plan" }
$EXTRA  = if ($args.Count -ge 3) { $args[2..($args.Count - 1)] } else { @() }

$validActions = @("plan", "apply", "destroy", "init", "validate", "output")
if ($validActions -notcontains $ACTION) {
  Write-Host "Invalid action: '$ACTION'" -ForegroundColor Red
  Write-Host ("Valid actions: " + ($validActions -join ', '))
  exit 1
}

function Resolve-Targets($t) {
  if ($t -eq "all") {
    return @(Get-ChildItem $ServicesDir -Directory | ForEach-Object { $_.Name })
  }
  if ($groups.ContainsKey($t)) { return $groups[$t] }
  if (Test-Path (Join-Path $ServicesDir $t)) { return @($t) }
  return @("UNKNOWN:$t")
}

$TARGETS = @()
$unknown = @()
foreach ($piece in @(($args[0] -split ','))) {
  $t = "$piece".Trim()
  if (-not $t) { continue }
  $r = @(Resolve-Targets $t)
  if ($r.Count -gt 0 -and $r[0] -like "UNKNOWN:*") { $unknown += "$($r[0].Substring(8))"; continue }
  $TARGETS += $r
}
$TARGETS = @($TARGETS | Select-Object -Unique)

if ($unknown.Count -gt 0) {
  Write-Host ("Unknown target(s): " + ($unknown -join ', ')) -ForegroundColor Red
  Write-Host "Available services: $((Get-ChildItem $ServicesDir -Directory).Name -join ' ')"
  Write-Host "Available groups: $($groups.Keys -join ' ') all"
  exit 1
}
if ($TARGETS.Count -eq 0) { Usage }

$exitCode = 0
foreach ($svc in $TARGETS) {
  $dir = Join-Path $ServicesDir $svc
  if (-not (Test-Path $dir)) { Write-Host "Missing service dir: $dir" -ForegroundColor Red; $exitCode = 1; continue }
  Write-Host ""
  Write-Host "======================================================" -ForegroundColor Cyan
  Write-Host "  terraform $ACTION  ->  services/$svc" -ForegroundColor Cyan
  Write-Host "======================================================" -ForegroundColor Cyan
  Set-Location $dir
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & terraform init -input=false
    if ($LASTEXITCODE -eq 0) {
      & terraform $ACTION @EXTRA
    }
    if ($LASTEXITCODE -ne 0) { Write-Host "!! Failed: services/$svc" -ForegroundColor Red; $exitCode = 1 }
  } finally {
    $ErrorActionPreference = $prev
    Set-Location $Root
  }
}

exit $exitCode
