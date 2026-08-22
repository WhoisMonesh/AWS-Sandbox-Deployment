# Troubleshooting Scenarios

Each file here is **intentionally broken**. Deploy it, observe the failure, then
fix it (the fix is described below). Great for building `kubectl` debugging muscle.

| File | Symptom you'll see | Root cause |
|------|--------------------|------------|
| `image-pull-backoff.yaml`     | `ImagePullBackOff` / `ErrImagePull` | image tag that does not exist |
| `crash-loop-backoff.yaml`     | `CrashLoopBackOff`                  | container process exits immediately |
| `pending-pod.yaml`           | `Pending` (never schedules)         | resource request exceeds node capacity |
| `oomkilled.yaml`             | `OOMKilled` (RestartCount climbing) | memory limit too small for the workload |
| `config-error.yaml`          | `CreateContainerConfigError`        | references a ConfigMap/Secret that doesn't exist |

## How to investigate

```bash
kubectl apply -f <file>.yaml -n practice
kubectl get pods -n practice -w
kubectl describe pod <pod> -n practice     # Events section is the key
kubectl logs <pod> -n practice --previous  # last crashed container
```

---

## image-pull-backoff.yaml
**Symptom:** `kubectl get pods` shows `ErrImagePull` / `ImagePullBackOff`.
**Fix:** the image `nginx:1.999` does not exist. Change the tag to a real one
(e.g. `nginx:1.27`) and re-apply:
```bash
kubectl set image deployment/broken broken=nginx:1.27 -n practice
# or edit the file and: kubectl apply -f image-pull-backoff.yaml -n practice
```

## crash-loop-backoff.yaml
**Symptom:** `CrashLoopBackOff`, RestartCount increasing.
**Fix:** the command runs `exit 1` immediately. Replace with a long-running
process, e.g. `command: ["sh","-c","sleep 3600"]`, then re-apply.

## pending-pod.yaml
**Symptom:** Pod stays `Pending`; `describe pod` → `FailedScheduling:
insufficient cpu`.
**Fix:** requests `cpu: 9` (9 cores) but nodes have <2 cores. Lower the request
to something schedulable (e.g. `cpu: 100m`) and re-apply.

## oomkilled.yaml
**Symptom:** Pod `OOMKilled`, RestartCount climbing (check `describe` →
`OOMKilled` / `kubectl get pod` shows `RESTARTS`).
**Fix:** the python workload allocates far more than the `16Mi` limit. Raise the
memory limit (e.g. `256Mi`) or remove the allocation, then re-apply.

## config-error.yaml
**Symptom:** `CreateContainerConfigError`; `describe pod` →
`configmap "missing-config" not found`.
**Fix:** the Pod mounts/reads `missing-config` which isn't created. Either create
that ConfigMap, or point the Pod at an existing one (or remove the reference),
then re-apply.

---

Clean up after each: `kubectl delete -f <file>.yaml -n practice`
