#!/usr/bin/env bash
#
# setup-creds.sh — Interactive AWS credential bootstrap for the
# KodeKloud AWS Playground (IAM user sign-in).
#
# It asks for:
#   - AWS account sign-in URL  (e.g. https://905418106103.signin.aws.amazon.com/console)
#   - IAM username              (e.g. kk_labs_user_997918)
#   - Console password          (used ONLY for the `aws login` browser flow; never stored)
#   - Region                    (default: us-east-1)
#
# Strategy (auto-fallback):
#   1. Try `aws login` (AWS CLI >= 2.32, browser or --remote for headless).
#      Requires the IAM permission SignInLocalDevelopmentAccess (managed
#      policy SignInLocalDevelopmentAccess). On success it creates a
#      `kk-playground-login` profile and a `kk-playground` profile that
#      bridges to it via `credential_process`.
#   2. If `aws login` is denied, fall back to long-lived IAM access keys:
#      the script opens the IAM console "Security credentials" page so you
#      can create a key, then it stores the key pair in the `kk-playground`
#      profile. The console password is never written to disk.
#
# Everything is written to ~/.aws/config under the `kk-playground` profile.
# Nothing credential-related is ever written into this repository.
#
set -euo pipefail

PROFILE="kk-playground"
LOGIN_PROFILE="kk-playground-login"
AWS_CLI="${AWS_CLI:-aws}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '\033[36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$1"; }
ok()   { printf '\033[32m✔\033[0m %s\n' "$1"; }

command -v "$AWS_CLI" >/dev/null 2>&1 || { echo "aws CLI not found. Install it first: https://docs.aws.amazon.com/cli/"; exit 1; }

# --- Collect inputs -------------------------------------------------------
bold "KodeKloud AWS Playground — credential setup"
echo

# The KodeKloud playground issues a fresh account/URL/user every session, so we
# always prompt (no stale default) and re-ask until a value is provided.
SIGNIN_URL="${KK_SIGNIN_URL:-}"
while [[ -z "${SIGNIN_URL}" ]]; do
  read -r -p "AWS account sign-in URL: " SIGNIN_URL
done

IAM_USER="${KK_IAM_USER:-}"
while [[ -z "${IAM_USER}" ]]; do
  read -r -p "IAM username: " IAM_USER
done

# Derive account id from the sign-in URL (https://<accountId>.signin.aws.amazon.com/...)
ACCOUNT_ID="$(printf '%s' "$SIGNIN_URL" | sed -E 's#https?://([0-9]{12})\.signin\.aws\.amazon\.com.*#\1#')"
if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "$SIGNIN_URL" ]]; then
  read -r -p "Could not parse account id from URL. Enter it manually: " ACCOUNT_ID
fi

# Password: only consumed by the browser `aws login` flow; not stored.
ASKPASS=1
if [[ -n "${KK_ACCESS_KEY_ID:-}" && -n "${KK_SECRET_ACCESS_KEY:-}" ]]; then ASKPASS=0; fi
if [[ "${KK_AUTH:-}" == "1" ]]; then ASKPASS=1; fi
if [[ "$ASKPASS" == "1" ]]; then
  read -r -s -p "Console password (used only for the browser login, never stored): " CONSOLE_PASS
  echo
fi

if [[ -n "${KK_REGION:-}" ]]; then
  REGION="$KK_REGION"
else
  read -r -p "Region [us-east-1]: " REGION
  REGION="${REGION:-us-east-1}"
fi

IAM_ARN="arn:aws:iam::${ACCOUNT_ID}:user/${IAM_USER}"

info "Account ID : $ACCOUNT_ID"
info "IAM user   : $IAM_USER"
info "Region     : $REGION"
echo

ensure_config_dir() {
  mkdir -p "$(aws configure get region >/dev/null 2>&1; echo "${HOME}/.aws")"
  mkdir -p "${HOME}/.aws"
}

# --- Attempt 1: aws login (with a timeout so it can never hang) ----------
try_aws_login() {
  info "Attempting 'aws login' (browser-based console credentials)..."
  local pid
  "$AWS_CLI" login --profile "$LOGIN_PROFILE" --region "$REGION" >/tmp/awlogin.out 2>&1 & pid=$!
  local waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge 150 ]; then
      warn "aws login did not complete within 150s (this lab user likely lacks SignInLocalDevelopmentAccess)."
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 3; waited=$((waited + 3))
  done
  if wait "$pid"; then
    ok "aws login succeeded."
    "$AWS_CLI" configure set profile."$PROFILE".region "$REGION"
    "$AWS_CLI" configure set profile."$PROFILE".credential_process \
      "aws configure export-credentials --profile $LOGIN_PROFILE --format process"
    "$AWS_CLI" configure set profile."$LOGIN_PROFILE".region "$REGION"
    "$AWS_CLI" configure set profile."$LOGIN_PROFILE".login_session "$IAM_ARN"
    return 0
  fi
  warn "aws login failed: $(tail -1 /tmp/awlogin.out 2>/dev/null)"
  return 1
}

# --- Attempt 2: long-lived access keys ----------------------------------
use_access_keys() {
  warn "Falling back to long-lived IAM access keys."
  AK="${KK_ACCESS_KEY_ID:-}"
  SK="${KK_SECRET_ACCESS_KEY:-}"
  if [[ -z "$AK" || -z "$SK" ]]; then
    echo "  1) Open the IAM console 'Security credentials' page for this user."
    echo "  2) Under 'Access keys' choose 'Create access key' (use case: CLI)."
    echo "  3) Copy the Access key ID and Secret access key."
    echo
    CONSOLE_CREDS_URL="https://${REGION}.console.aws.amazon.com/iam/home?region=${REGION}#/users/${IAM_USER}?section=security_credentials"
    if command -v open >/dev/null 2>&1; then
      open "$CONSOLE_CREDS_URL" >/dev/null 2>&1 || true
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$CONSOLE_CREDS_URL" >/dev/null 2>&1 || true
    fi
    echo "    (Opening: $CONSOLE_CREDS_URL)"
    echo
    if [[ -z "$AK" ]]; then read -r -p "Access Key ID: " AK; fi
    if [[ -z "$SK" ]]; then read -r -s -p "Secret Access Key: " SK; echo; fi
  fi
  "$AWS_CLI" configure unset profile."$PROFILE".credential_process 2>/dev/null || true
  "$AWS_CLI" configure set profile."$PROFILE".region "$REGION"
  "$AWS_CLI" configure set profile."$PROFILE".aws_access_key_id "$AK"
  "$AWS_CLI" configure set profile."$PROFILE".aws_secret_access_key "$SK"
  ok "Stored access keys in profile '$PROFILE'."
}

ensure_config_dir

# --- Clear any previously stored credentials ------------------------------
# Re-running this script must start from a clean slate so stale access keys or
# an old credential_process never linger alongside the new credentials.
clear_old_creds() {
  for p in "$PROFILE" "$LOGIN_PROFILE"; do
    "$AWS_CLI" configure unset profile."$p".aws_access_key_id    2>/dev/null || true
    "$AWS_CLI" configure unset profile."$p".aws_secret_access_key 2>/dev/null || true
    "$AWS_CLI" configure unset profile."$p".credential_process    2>/dev/null || true
  done
}
clear_old_creds

if [[ -n "${KK_AUTH:-}" ]]; then
  AUTH="$KK_AUTH"
else
  echo "How would you like to authenticate?"
  echo "  1) aws login (browser)  — requires IAM perm SignInLocalDevelopmentAccess (usually ABSENT on KodeKloud lab users; gives a 400)"
  echo "  2) Long-lived IAM access keys  — recommended for the KodeKloud playground"
  read -r -p "Choice [2]: " AUTH
  AUTH="${AUTH:-2}"
fi

if [ "$AUTH" = "1" ]; then
  if try_aws_login; then
    :
  else
    use_access_keys
  fi
else
  use_access_keys
fi

# --- Verify -------------------------------------------------------------
info "Verifying identity with 'aws sts get-caller-identity --profile $PROFILE'..."
if "$AWS_CLI" sts get-caller-identity --profile "$PROFILE" --region "$REGION" 2>/tmp/awsid.err; then
  ok "Credentials work. You can now run:  ./tf.sh <service> plan"
else
  warn "Identity check failed: $(cat /tmp/awsid.err)"
  warn "If you just created access keys, wait a few seconds and retry ./tf.sh."
fi
