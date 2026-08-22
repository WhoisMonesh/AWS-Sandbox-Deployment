# EKS Cluster + Jumpserver — Kubernetes Practice Lab

A self-contained Kubernetes practice environment: an EKS cluster fronted by a
**jumpserver (bastion host)** that already has `kubectl` configured. Everything
below runs from the bastion, so you can practice `kubectl` without touching AWS
directly.

---

## 1. Environment at a glance

| Component      | Value                                              |
|----------------|----------------------------------------------------|
| Cluster name   | `kk-lab-eks`                                       |
| Kubernetes     | `v1.36.x` (EKS)                                    |
| Nodes          | 2 × `t3.micro` (self-managed, AL2023 + `nodeadm`)  |
| Auth mode      | `API_AND_CONFIG_MAP`                               |
| Jumpserver     | `ec2-user@<bastion-public-ip>` (Amazon Linux 2023) |
| kubectl        | installed & pointed at `kk-lab-eks`                |

The worker nodes authenticate to the API server via client certificates; the
jumpserver reuses the node IAM role (sandbox `iam:PassRole` constraint) which is
mapped to `system:masters` in the `aws-auth` ConfigMap, so you have
cluster-admin from the bastion.

---

## 2. Connect to the jumpserver

```bash
# From your laptop
ssh -i ssh/kk-lab-bastion.pem ec2-user@<bastion-public-ip>

# On the jumpserver
cd ~/k8s-practice
kubectl get nodes
kubectl cluster-info
```

All practice YAMLs live under `~/k8s-practice` on the jumpserver (this repo:
`k8s-practice/`).

> **Tip:** Use `kubectl port-forward` / `kubectl exec` / `kubectl logs` for
> app access — the node Security Group does **not** open NodePort/LoadBalancer
> ranges to the internet. If you need external access, add a Security Group rule
> or deploy the AWS Load Balancer Controller first.

---

## 3. Practice manifest catalogue

| Folder | What you practice |
|--------|-------------------|
| `00-cluster-basics/`   | Namespaces, Deployments, Services (ClusterIP/NodePort) |
| `01-config-storage/`   | ConfigMap, Secret, PVC, consuming them in Pods |
| `02-probes/`           | Liveness & Readiness probes |
| `03-resources-scheduling/` | requests/limits, QoS, taints/tolerations |
| `04-workloads/`        | StatefulSet, DaemonSet, Job, CronJob |
| `05-rbac/`             | ServiceAccounts, Roles, RoleBindings |
| `06-networking/`       | NetworkPolicy (needs CNI policy support) |
| `07-troubleshooting/`  | Broken manifests + fix guides (see its `README.md`) |

Apply any example with:

```bash
kubectl apply -f 00-cluster-basics/
kubectl get all -n <namespace>
kubectl delete -f 00-cluster-basics/   # clean up when done
```

---

## 4. Daily workflow

```bash
# Create a sandbox namespace and set it as default for the session
kubectl create namespace practice
kubectl config set-context --current --namespace=practice

# Watch what you deploy
kubectl get pods -w

# Inspect
kubectl describe pod <pod>
kubectl logs <pod> [-c <container>] [-f]
kubectl exec -it <pod> -- sh
```

---

## 5. Troubleshooting command cheat-sheet

```bash
kubectl get events --sort-by=.lastTimestamp        # cluster events
kubectl describe pod <pod>                          # why pending/crash
kubectl logs <pod> --previous                      # last crashed container
kubectl top nodes; kubectl top pods                 # resource usage (metrics-server)
kubectl get pod <pod> -o yaml                      # full spec + status
kubectl rollout status deploy/<name>               # deployment progress
kubectl rollout undo deploy/<name>                 # rollback
kubectl auth can-i create pods --as=system:serviceaccount:practice:default  # RBAC check
```

Common failure reasons & where to look:
- **Pending** → `describe pod` → insufficient CPU/memory, no matching node, PVC unbound.
- **ImagePullBackOff** → bad image name / tag / registry auth.
- **CrashLoopBackOff** → app exits; check `logs --previous`.
- **CreateContainerConfigError** → missing ConfigMap/Secret referenced by the Pod.
- **OOMKilled** → memory limit too low (`kubectl top` / events).

See `07-troubleshooting/README.md` for hands-on broken scenarios.

---

## 6. Cleanup

```bash
kubectl delete namespace practice          # wipes everything you made there
kubectl delete -f <folder>/                # or per-folder
```
