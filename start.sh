#!/usr/bin/env bash
#
# start.sh — KodeKloud AWS Playground bootstrap for macOS / Ubuntu-Linux / WSL2.
#
# What it does:
#   1. Detects the OS (macOS, Ubuntu, WSL).
#   2. Idempotently installs core prerequisites: aws-cli v2, terraform, jq, git, unzip.
#   3. Runs setup-creds.sh to configure the `kk-playground` AWS profile
#      (interactive: account URL / IAM user / password + `aws login` or access keys).
#   4. Presents a menu to deploy sandbox services one at a time (via tf.sh),
#      respecting the playground's per-account resource caps.
#
# Usage:  ./start.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

info() { printf '\033[36m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$1"; }

# ---------------- Prerequisite installation ----------------
install_mac() {
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  for p in awscli jq git unzip; do
    command -v "${p%%-*}" >/dev/null 2>&1 || brew install "$p"
  done
  if ! command -v terraform >/dev/null 2>&1; then
    brew tap hashicorp/tap >/dev/null 2>&1 || true
    brew install hashicorp/tap/terraform
  fi
}

install_linux() {
  sudo apt-get update -y
  sudo apt-get install -y jq git unzip curl gnupg software-properties-common ca-certificates

  if ! command -v aws >/dev/null 2>&1 || [[ "$(aws --version 2>/dev/null)" != aws-cli/2* ]]; then
    info "Installing AWS CLI v2..."
    curl -sSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
    unzip -o /tmp/awscliv2.zip -d /tmp/awscli >/dev/null 2>&1 || true
    sudo /tmp/awscli/aws/install || true
  fi

  if ! command -v terraform >/dev/null 2>&1; then
    info "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y terraform
  fi
}

detect_and_install() {
  local os
  os="$(uname -s)"
  if [[ "$os" == "Darwin" ]]; then
    info "Detected macOS."
    install_mac
  elif [[ "$os" == "Linux" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
      info "Detected WSL (Ubuntu)."
    else
      info "Detected Linux (Ubuntu)."
    fi
    install_linux
  else
    warn "Unsupported OS: $os. Install aws-cli, terraform, jq, git, unzip manually."
  fi
}

detect_and_install

info "Verifying prerequisites:"
for c in aws terraform jq git unzip; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c -> $($c --version 2>&1 | head -1)"; else warn "$c is missing"; fi
done

# ---------------- Credential bootstrap ----------------
if [[ ! -f setup-creds.sh ]]; then
  warn "setup-creds.sh not found; skipping credential setup. Run it manually."
else
  info "Running interactive credential setup (kk-playground profile)..."
  ./setup-creds.sh
fi

# ---------------- Deploy menu ----------------
deploy_menu() {
  while true; do
    echo
    echo "Available services:"
    ls services 2>/dev/null | tr '\n' ' '; echo
    echo "Groups: group-core group-storage group-database group-network group-integration group-security group-monitor group-devtools group-tools"
    echo
    read -r -p "Deploy target (service / group / 'all' / q to quit): " TGT
    [[ "$TGT" == "q" || -z "$TGT" ]] && { echo "Bye."; break; }
    read -r -p "Action [plan|apply|destroy] (default plan): " ACT
    ACT="${ACT:-plan}"
    ./tf.sh "$TGT" "$ACT"
  done
}

deploy_menu
