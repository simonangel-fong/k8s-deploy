# Host-level canary (final state before blue-green)

Snapshot of the backend chart + ArgoCD Application in its last host-level
canary state (with `resources`, replicas=5, timed pauses) before rewriting
for blue-green.

## Files

| File | Original path |
|---|---|
| `rollout.yaml`               | `app/backend/templates/rollout.yaml` |
| `service.yaml`               | `app/backend/templates/service.yaml` |
| `virtualservice.yaml`        | `app/backend/templates/virtualservice.yaml` |
| `values.yaml`                | `app/backend/values.yaml` |
| `argocd-app-02-backend.yaml` | `argocd/apps/02-backend.yaml` |

## Restore

Copy files back to their original paths.
