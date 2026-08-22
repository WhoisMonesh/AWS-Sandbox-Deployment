#!/usr/bin/env bash
#
# reset-state.sh — Wipe ALL local Terraform artifacts for every service:
# state files, provider lock files, .terraform caches, plan and crash logs.
#
# WHY: KodeKloud gives you a FRESH AWS account each lab session. The local
# *.tfstate files (git-ignored, so they persist on disk between sessions)
# still describe resources in the PREVIOUS account, and .terraform/ caches +
# lock files go stale too. Drop them all and let terraform treat everything
# as brand new in the current account (init re-downloads providers).
#
# USAGE: ./reset-state.sh [-y]    (-y skips the confirmation prompt)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES="$ROOT/services"

ASSUME_YES=0
case "${1:-}" in
  -y|--yes) ASSUME_YES=1 ;;
  "") ;;
  *) echo "Usage: $0 [-y]"; exit 1 ;;
esac

echo "This will DELETE under $SERVICES :"
echo "  - .terraform/                 (provider/module caches)"
echo "  - .terraform.lock.hcl         (provider lock files)"
echo "  - terraform.tfstate(.backup)  (local state)"
echo "  - terraform.tfstate.lock.info, *.tfplan, crash.log*"
echo

if (( ! ASSUME_YES )); then
  read -r -p "Proceed? [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

count=0
while IFS= read -r -d '' p; do
  rm -rf "$p"
  echo "  removed $p"
  count=$((count + 1))
done < <(
  find "$SERVICES" -maxdepth 2 \( \
      -name '.terraform' -o \
      -name '.terraform.lock.hcl' -o \
      -name 'terraform.tfstate' -o \
      -name 'terraform.tfstate.backup' -o \
      -name 'terraform.tfstate.lock.info' -o \
      -name 'crash.log*' -o \
      -name '*.tfplan' \) -print0 2>/dev/null
)

(( count )) || echo "  Nothing to remove — already clean."

echo
echo "Done. Next: ./tf.sh <service> plan   (init runs automatically)"
