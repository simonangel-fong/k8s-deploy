# Subset-level canary (backup)

Snapshot of the backend chart + ArgoCD Application using Istio
DestinationRule subsets for canary traffic split. Kept for reference only —
not synced by ArgoCD.

## What defines subset-level

- **Single Service** (`backend`) matching all backend pods.
- **DestinationRule** with two subsets `stable` and `canary`. Argo Rollouts
  injects `rollouts-pod-template-hash: <hash>` into each subset's labels at
  runtime so each subset resolves to one ReplicaSet.
- **VirtualService** weights traffic between the two subsets on the same
  host (not between two Services as in host-level).
- **Rollout** references `destinationRule.name` +
  `stableSubsetName` / `canarySubsetName` — no `stableService` /
  `canaryService` fields.

## Files

| File                         | Original path                                |
| ---------------------------- | -------------------------------------------- |
| `rollout.yaml`               | `app/backend/templates/rollout.yaml`         |
| `service.yaml`               | `app/backend/templates/service.yaml`         |
| `virtualservice.yaml`        | `app/backend/templates/virtualservice.yaml`  |
| `destinationrule.yaml`       | `app/backend/templates/destinationrule.yaml` |
| `argocd-app-02-backend.yaml` | `argocd/apps/02-backend.yaml`                |

## Restore

Copy files back to their original paths (see table above). No other files
need changing.
