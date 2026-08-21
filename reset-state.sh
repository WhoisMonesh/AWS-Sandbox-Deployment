#!/usr/bin/env bash
#
# reset-state.sh — Wipe local Terraform state for every service.
#
# WHY: KodeKloud gives you a FRESH AWS account each lab session. The local
# *.tfstate files (git-ignored, so they persist on disk between sessions)
# still describe resources in the PREVIOUS account. When you run terraform in
# the new account it tries to refresh those old resources, producing errors
# like "AccountIDs mismatch" (ECS) or cross-account AccessDenied (S3).
#
# The previous account is gone, so those resources can't be destroyed — just
# drop the local state and let terraform treat everything as brand new in the
# current account.
#
# USAGE: ./reset-state.sh   (then: ./tf.sh group-core apply)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Wiping local Terraform state under $ROOT/services ..."
count=0
while IFS= read -r -d '' f; do
  rm -f "$f"
  echo "  removed $f"
  count=$((count + 1))
done < <(find "$ROOT/services" -maxdepth 2 \( -name 'terraform.tfstate' -o -name 'terraform.tfstate.backup' \) -print0)

if [ "$count" -eq 0 ]; then
  echo "  (nothing to remove — state already clean)"
fi

echo
echo "Done. Next: ./tf.sh group-core apply   (or ./tf.sh <service> apply)"
