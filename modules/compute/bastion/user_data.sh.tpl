#!/bin/bash
set -euo pipefail

# Amazon Linux 2023 ships the AWS CLI v2 preinstalled; we only need kubectl.
KUBECTL_VERSION="${kubectl_version}"

if ! command -v kubectl >/dev/null 2>&1; then
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
  chmod +x /tmp/kubectl
  mv /tmp/kubectl /usr/local/bin/kubectl
fi

# Helper script so the user can re-run kubectl setup after access entry propagates.
cat > /usr/local/bin/connect-eks.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail
aws eks update-kubeconfig --region ${region} --name ${cluster_name}
kubectl get nodes
SCRIPT
chmod +x /usr/local/bin/connect-eks.sh

# Best-effort initial connect (may need a re-run while the access entry propagates).
/usr/local/bin/connect-eks.sh || true
kubectl get nodes || true
