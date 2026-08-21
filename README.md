# KodeKloud — All AWS Services Deployment (Playground Lab)

A complete, hands-on Terraform lab for practicing **every service offered by the
KodeKloud AWS Playground** from your local machine (macOS / Ubuntu-Linux / WSL2 / native Windows).

Each AWS service has:
- a reusable Terraform **module** under `modules/<category>/<service>/`
- a deployable **root** under `services/<service>/` (calls the module with the `kk-playground` profile)

All modules are written to respect the playground's sandbox limits (instance
types, CPU credit mode, volume size, Lambda memory/timeout, Cognito policy, etc.).

---

## 1. Prerequisites (auto-installed by the start script)
`aws-cli` v2, `terraform` (>= 1.x, AWS provider >= 5), `jq`, `git`, `unzip`.

## 2. Quick start
### macOS / Ubuntu / WSL2
```bash
./start.sh          # installs prereqs, configures creds, then a deploy menu
```
Or manually:
```bash
./setup-creds.sh    # interactive: account URL / IAM user / password
./tf.sh ec2 plan
./tf.sh ec2 apply
```

### Windows (native PowerShell)
```powershell
.\start.ps1         # installs prereqs via winget, configures creds, deploy menu
```
Or manually:
```powershell
.\setup-creds.ps1
.\tf.ps1 ec2 plan
.\tf.ps1 ec2 apply
```

## 3. How credentials work
The playground gives you a **console sign-in** (account URL + IAM user + password).
`setup-creds.sh` / `setup-creds.ps1` tries `aws login` (AWS CLI ≥ 2.32) first, which
turns console credentials into temporary programmatic credentials — no long-lived
keys needed. If the lab user lacks `SignInLocalDevelopmentAccess`, it falls back to
creating IAM access keys in the console. Everything is stored in the `kk-playground`
AWS profile (`~/.aws/config` / `%USERPROFILE%\.aws\config`); **nothing is written into this repo.**

## 4. Deploy a service (never all at once)
The sandbox enforces hard caps (5 EC2 instances, 3 stopped, 3 pods/ns, 8 RPU
Redshift, etc.), so deploy **one service or one group at a time**:

```bash
./tf.sh ec2 apply                 # single service
./tf.sh group-core apply          # IAM/VPC, EC2, S3, RDS, Lambda, DynamoDB, EKS, ECR, ECS
./tf.sh group-network destroy
```

Groups: `group-core`, `group-storage`, `group-database`, `group-network`,
`group-integration`, `group-security`, `group-monitor`, `group-devtools`, `group-tools`.

## 5. Repository layout
```
setup-creds.sh  setup-creds.ps1   # interactive credential bootstrap (bash / pwsh)
start.sh        start.ps1         # cross-platform bootstrap (prereqs + creds + menu)
tf.sh           tf.ps1            # deploy wrapper (per service / group)
modules/<cat>/<svc>/               # reusable, sandbox-compliant Terraform modules
services/<svc>/                   # deployable root that calls a module
docs/CONSOLE_ONLY.md              # services that are console/SDK-only (no TF module)
```

## 6. Cleanup
Always tear down what you deploy to avoid hitting caps / charges:
```bash
./tf.sh <service> destroy
```

## 7. Notes
- EKS/ECS assume the playground-provided `eksClusterRole` / `AmazonEKSNodeRole`.
- The EKS cluster runs **Kubernetes 1.36** and grants the lab IAM role
  (`kk-lab-lab-role`, created by the `iam-vpc` module) cluster-admin via an EKS
  access entry, so the bastion host can manage it with `kubectl`.
- Because the EKS module now looks up the `kk-lab-lab-role` (from `iam-vpc`),
  **deploy EKS after IAM/VPC** — `./tf.sh group-core apply` already does this in
  order (`iam-vpc … eks … bastion`). A standalone `./tf.sh eks apply` requires the
  `iam-vpc` service to have been applied first.
- Some services (e.g. `directory-service`, `redshift-serverless`) provision billable
  resources; destroy promptly after practicing.
- See `docs/CONSOLE_ONLY.md` for services that have no Terraform module.

## 8. Bastion host (SSH + kubectl)
Need a shell with `kubectl` against the EKS cluster? Deploy the bastion:

```bash
./tf.sh group-core apply        # brings up iam-vpc, eks, then the bastion
# or just the bastion after the core is up:
./tf.sh bastion apply
```

The bastion provisions an Amazon Linux 2023 instance in the lab public subnet,
generates an RSA key pair (written to `ssh/kk-lab-bastion.pem`, gitignored),
installs `kubectl` (pinned to the cluster minor version), and wires EKS access
through its IAM instance profile. Full cross-platform SSH/`kubectl` steps and the
lab-IAM caveats are in **`docs/BASTION.md`**.

```bash
# from the output of `./tf.sh bastion apply`:
ssh -i ssh/kk-lab-bastion.pem ec2-user@<BASTION_PUBLIC_IP>
# on the bastion:
connect-eks.sh        # aws eks update-kubeconfig + kubectl get nodes
```
