# Bastion Host — SSH & kubectl into the KodeKloud EKS Cluster

The `bastion` service launches a small Amazon Linux 2023 EC2 instance in the lab
public subnet so you have a shell with `kubectl` pointed at the `kk-lab-eks`
cluster (Kubernetes **1.36**). The bastion authenticates to EKS using its IAM
instance profile (`kk-lab-lab-role`), which the EKS module grants cluster-admin
via an EKS **access entry**.

> The bastion depends on resources created by the `iam-vpc` module (VPC, public
> subnet, lab instance profile) and the `eks` module (cluster + access entry).
> Always apply it **after** those — `./tf.sh group-core apply` does this in order.

---

## 1. Deploy

```bash
# Full core stack (iam-vpc → … → eks → bastion):
./tf.sh group-core apply

# Or just the bastion once the core is up:
./tf.sh bastion apply
```

Terraform prints the SSH command and the bastion public IP. They are also in the
outputs (`ssh_command`, `bastion_public_ip`).

---

## 2. SSH to the bastion

### macOS / Linux / WSL2
```bash
chmod 600 ssh/kk-lab-bastion.pem
ssh -i ssh/kk-lab-bastion.pem ec2-user@<BASTION_PUBLIC_IP>
```

### Windows (native, OpenSSH in PowerShell)
```powershell
icacls ssh\kk-lab-bastion.pem /inheritance:r
icacls ssh\kk-lab-bastion.pem /grant:r "%USERNAME%:R"
ssh -i ssh\kk-lab-bastion.pem ec2-user@<BASTION_PUBLIC_IP>
```
> If OpenSSH isn't installed: *Settings → Apps → Optional features → Add a feature →
> OpenSSH Client*, or use PuTTY with the key converted via `puttygen`.

### Git Bash / MINGW
```bash
chmod 600 ssh/kk-lab-bastion.pem
ssh -i ssh/kk-lab-bastion.pem ec2-user@<BASTION_PUBLIC_IP>
```

The default user is `ec2-user` (AL2023). The generated key lives at
`ssh/kk-lab-bastion.pem` and is excluded by `.gitignore` (`ssh/`, `*.pem`).

---

## 3. Connect kubectl to the cluster

On the bastion, `aws` uses the instance's IAM role automatically (no static
creds needed). A helper script is preinstalled:

```bash
connect-eks.sh        # runs: aws eks update-kubeconfig --region us-east-1 --name kk-lab-eks
kubectl get nodes
kubectl get ns
```

If `kubectl get nodes` returns `Forbidden`/`Unauthorized` on the first try, the
EKS access entry may still be propagating — wait ~30s and re-run `connect-eks.sh`.

---

## 4. Tear down

```bash
./tf.sh bastion destroy
```

---

## 5. Lab IAM caveats (read me)

The KodeKloud Playground `AWS_EKSECSWithConditions` policy is restrictive:

- **Access entry creation** — the EKS module creates an
  `aws_eks_access_entry` + `AmazonEKSClusterAdminPolicy` association for the lab
  role. If the lab policy blocks `eks:CreateAccessEntry`, the `eks` apply fails at
  that step. Disable it with:

  ```hcl
  module "eks" {
    source             = "../../modules/container/eks"
    create_access_entry = false
  }
  ```
  and instead manage `aws-auth` manually (note: applying `aws-auth` itself needs
  existing cluster access).

- **EKS API permissions for the bastion** — the EKS access entry grants
  Kubernetes RBAC only. To actually call `aws eks update-kubeconfig` and the
  kubectl exec plugin, the bastion's instance profile (the lab role) also needs
  the AWS-side `eks:DescribeCluster` / `eks:GetToken` permissions. The bastion
  module attaches a small inline policy for this. If the lab policy blocks
  `iam:PutRolePolicy` on the lab role, disable it:

  ```hcl
  module "bastion" {
    source                  = "../../modules/compute/bastion"
    grant_eks_api_permissions = false
  }
  ```
  and attach the EKS perms to the lab role another way (or run `update-kubeconfig`
  from a principal that already has them).

- **No managed node groups / Fargate** — `eks:CreateNodegroup` and the Fargate
  prerequisites (`iam:PassRole` to `eks-fargate-pods.amazonaws.com`,
  `iam:PutRolePolicy`/`AttachRolePolicy` for the Fargate pod execution role) are
  not permitted. The EKS module deploys the **control plane only**. The bastion is
  purely an admin jump host — you still cannot schedule workloads without node
  capacity the lab policy forbids.

- **Public endpoint only** — the cluster uses `endpoint_public_access = true`, so
  the bastion reaches the API server over the internet (it sits in a public subnet
  with an IGW route). No VPC peering / private-link is required for `kubectl`.

- **SSH exposure** — the bastion security group allows TCP/22 from
  `0.0.0.0/0` by default (`ssh_cidr` variable). For anything beyond the lab,
  narrow this to your IP/CIDR.
