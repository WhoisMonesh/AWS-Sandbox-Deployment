# Create / Launch an EKS Cluster for Kubernetes Practice

This document explains how to spin up a real Amazon EKS cluster using this repo's
Terraform so you have a sandbox to practice `kubectl`, Deployments, probes,
RBAC, networking, and the troubleshooting scenarios in
[`k8s-practice/README.md`](../k8s-practice/07-troubleshooting/README.md).

> The cluster is deployed with the **`kk-playground`** AWS profile against the
> **KodeKloud AWS Playground** account. It deliberately mirrors the KodeKloud
> course workflow (self-managed nodes joined via the node IAM role) because the
> sandbox blocks `eks:CreateNodegroup`.

---

## 1. What gets created

| Resource | Name | Notes |
|----------|------|-------|
| EKS control plane | `kk-lab-eks` (v1.36) | Public API endpoint; `API_AND_CONFIG_MAP` auth mode; deploying principal gets cluster-admin |
| Cluster IAM role | `eksClusterRole` | `AmazonEKSClusterPolicy` (sandbox requires this exact name) |
| Worker IAM role | `eksWorkerNodeRole` | Worker node + CNI + ECR + SSM policies (sandbox requires this exact name) |
| Worker nodes | 2 × `t3.micro` (AL2023 EKS-optimized AMI) | Self-managed, launched by a CloudFormation AutoScalingGroup; `nodeadm init` joins them |
| Node security group | `kk-lab-eks-node-sg` | Node↔node + control-plane↔node rules |
| SSH key pair | `kk-lab-eks-node-key` | Private key written to `ssh/kk-lab-eks-node.pem` (gitignored) |
| `aws-auth` ConfigMap | `kube-system/aws-auth` | Maps the node role to `system:bootstrappers`/`system:nodes` (and `system:masters` for bastion reuse) |

Networking uses the **default VPC** and its default subnets (the unsupported AZ
`us-east-1e` is automatically excluded). No custom VPC is required.

---

## 2. Prerequisites

- `aws-cli` v2, `terraform` (>= 1.x, AWS provider >= 5), `kubectl`.
  (`aws`, `terraform`, `jq`, `git` are auto-installed by `./start.sh`.)
- The `kk-playground` AWS profile configured (see below).
- An EKS-kubeconfig-capable `kubectl` (any recent version).

---

## 3. Configure credentials (one time)

```bash
./setup-creds.sh      # interactive: account URL / IAM user / password
                      # -> creates the `kk-playground` AWS profile
```

This stores credentials only in `~/.aws/config` — **nothing is written into the
repo**.

---

## 4. Launch the cluster

Use the Terraform wrapper (recommended):

```bash
./tf.sh eks apply
```

Or run Terraform directly:

```bash
cd services/eks
terraform init
terraform apply
```

Apply takes ~10–15 min: the control plane comes up first, then the
CloudFormation worker stack. On success you'll see outputs like
`cluster_endpoint`, `node_autoscaling_group`, and `oidc_provider_arn`.

### Control-plane only (no worker nodes)

If you only want the API server (e.g. to test `kubectl` connectivity or IRSA
without paying for nodes):

```bash
cd services/eks
terraform apply -var="create_node_group=false"
```

---

## 5. Connect with kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name kk-lab-eks \
  --profile kk-playground

kubectl get nodes                 # should show 2 Ready nodes
kubectl get ns                   # confirm API access
```

The deploying principal is cluster-admin (via
`bootstrap_cluster_creator_admin_permissions`), so no extra RBAC step is needed
to start practicing.

---

## 6. Verify the cluster is healthy

```bash
kubectl get nodes -o wide
kubectl get pods -A              # core-dns / kube-proxy should be Running
kubectl cluster-info
```

If nodes stay `NotReady`, check the ASG instances and the node `user_data`
(`nodeadm init`) via SSM Session Manager — the node key in `ssh/` also allows
direct SSH for debugging.

---

## 7. Practice

Once `kubectl get nodes` shows Ready nodes, deploy the example manifests:

```bash
kubectl create namespace practice
kubectl apply -f k8s-practice/00-cluster-basics/
kubectl apply -f k8s-practice/01-config-storage/
# ... and so on. See k8s-practice/07-troubleshooting/README.md for broken scenarios.
```

A bastion host is also available (`services/bastion`) if you want an in-VPC
jump box, but it is **not required** — you can drive the cluster entirely from
local `kubectl`.

---

## 8. Tear down

```bash
./tf.sh eks destroy
# or: cd services/eks && terraform destroy
```

This deletes the control plane, the worker CloudFormation stack, IAM roles,
security group, and SSH key. The downloaded `kubeconfig` entry is left in your
local `~/.kube/config` (harmless; remove with
`kubectl config delete-context arn:aws:eks:us-east-1:...:cluster/kk-lab-eks`).

---

## 9. Notes & sandbox constraints

- **Fixed role names:** the playground only permits `iam:PassRole` on
  `eksClusterRole` and `eksWorkerNodeRole`, so these names are hardcoded —
  don't change them.
- **Node types:** limited to `t2/t3` nano|micro|small|medium (default `t3.micro`,
  desired 2, min 1, max 3).
- **Region:** `us-east-1` only (the module excludes `us-east-1e`).
- **Self-managed nodes** are used on purpose to avoid the blocked managed
  node-group API; they're joined the same way the KodeKloud course does.
- **SSH key** is generated per-apply into `ssh/kk-lab-eks-node.pem`; keep it
  safe (it is gitignored).
