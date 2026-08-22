#!/usr/bin/env bash
#
# tf.sh — Thin wrapper around Terraform for the KodeKloud AWS Playground lab.
#
# Usage:
#   ./tf.sh "<target[,target2,...]>" <action> [extra terraform args...]
#
#   target : a service under services/  (e.g. ec2, s3, rds, eks)
#            or a group  (group-core)  — see GROUPS below
#            or a comma-separated list  (e.g. "eks,bastion")
#            or  all      (NOT recommended; hits sandbox caps)
#   action : plan | apply | destroy | init | validate | output   (default: plan)
#
# Examples:
#   ./tf.sh ec2 plan
#   ./tf.sh s3 apply
#   ./tf.sh "eks,bastion" apply
#   ./tf.sh group-core destroy
#   ./tf.sh rds apply -auto-approve
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$ROOT/services"

GROUPS_group_core="iam-vpc ec2 s3 rds lambda dynamodb eks ecr ecs bastion"
GROUPS_group_storage="s3 ebs efs"
GROUPS_group_database="rds dynamodb redshift-serverless"
GROUPS_group_network="apigateway route53 waf elb service-discovery internet-monitor"
GROUPS_group_integration="stepfunctions kinesis eventbridge sns sqs appmesh appsync apprunner"
GROUPS_group_security="cognito kms acm acm-pca"
GROUPS_group_monitor="cloudwatch cloudtrail config inspector xray ssm cloudwatch-synthetics cloudwatch-rum application-insights cloudwatch-logs"
GROUPS_group_devtools="codedeploy codeartifact"
GROUPS_group_tools="autoscaling app-autoscaling secrets-manager cloudformation datasync directory-service evidently"

usage() {
  echo 'Usage: '"$0"' "<svc[,svc2,...]|group-xxx|all>" <plan|apply|destroy|init|validate|output> [args]'
  exit 1
}

[[ $# -ge 1 ]] || usage
TARGET="${1:-}"
ACTION="${2:-plan}"
case "$ACTION" in
  plan|apply|destroy|init|validate|output) ;;
  *) echo "Invalid action: $ACTION"
     echo "Valid actions: plan apply destroy init validate output"
     echo "Hint: quote comma lists, e.g. ./tf.sh \"eks,bastion\" plan"
     exit 1 ;;
esac
shift 2 || true
EXTRA=("$@")

TARGET_LIST="${TARGET//,/ }"
TARGETS=()
UNKNOWN=()
for t in $TARGET_LIST; do
  if [[ "$t" == all ]]; then
    mapfile -t arr < <(find "$SERVICES_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort)
    TARGETS+=("${arr[@]}")
    continue
  fi
  local_us="${t//-/_}"
  grp="GROUPS_${local_us}"
  if [[ -n "${!grp:-}" ]]; then
    read -ra arr <<< "${!grp}"
    TARGETS+=("${arr[@]}")
  elif [[ -d "$SERVICES_DIR/$t" ]]; then
    TARGETS+=("$t")
  else
    UNKNOWN+=("$t")
  fi
done
# dedupe, preserving order
if (( ${#TARGETS[@]} )); then
  mapfile -t TARGETS < <(printf '%s\n' "${TARGETS[@]}" | awk '!seen[$0]++')
fi

if (( ${#UNKNOWN[@]} )); then
  echo "Unknown target(s): ${UNKNOWN[*]}"
  echo "Available services:"; ls "$SERVICES_DIR" 2>/dev/null
  echo "Available groups: group-core group-storage group-database group-network group-integration group-security group-monitor group-devtools group-tools all"
  exit 1
fi
if (( ${#TARGETS[@]} == 0 )); then usage; fi

run_in() {
  local dir="$1"
  echo
  echo "──────────────────────────────────────────────────────"
  echo "▶ terraform $ACTION  ->  $dir"
  echo "──────────────────────────────────────────────────────"
  (
    cd "$dir" && terraform init -input=false -no-color

    # apply/destroy normally prompt for confirmation; auto-approve them so a
    # single `./tf.sh group-core apply` runs end-to-end without interaction.
    if [[ "$ACTION" == apply || "$ACTION" == destroy ]]; then
      case " ${EXTRA[*]:-} " in
        *" -auto-approve "*|*" --auto-approve "*|*" -auto-approve"|*"--auto-approve"*) ;;
        *) EXTRA+=(-auto-approve) ;;
      esac
    fi

    if [ ${#EXTRA[@]} -eq 0 ]; then
      terraform "$ACTION"
    else
      terraform "$ACTION" "${EXTRA[@]}"
    fi
  )
}

EXIT=0
for svc in "${TARGETS[@]}"; do
  dir="$SERVICES_DIR/$svc"
  if [[ ! -d "$dir" ]]; then
    echo "Missing service dir: $dir"; EXIT=1; continue
  fi
  if ! run_in "$dir"; then
    echo "!! Failed: services/$svc"
    EXIT=1
  fi
done

exit $EXIT
