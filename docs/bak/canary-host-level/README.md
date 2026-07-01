# Host-level canary (backup)

Snapshot of the backend chart + ArgoCD Application before migrating to
subset-level canary. Kept for reference only — not synced by ArgoCD.

## What defines host-level

- Two Services: `backend-stable`, `backend-canary`. Argo Rollouts patches
  each Service's `.spec.selector` at runtime with
  `rollouts-pod-template-hash: <hash>` to bind stable/canary to different
  ReplicaSets.
- VirtualService weights traffic between two `destination.host` values
  (the two Services).
- No DestinationRule needed.

## Files

| File | Original path |
|---|---|
| `rollout.yaml`               | `app/backend/templates/rollout.yaml` |
| `service.yaml`               | `app/backend/templates/service.yaml` |
| `virtualservice.yaml`        | `app/backend/templates/virtualservice.yaml` |
| `argocd-app-02-backend.yaml` | `argocd/apps/02-backend.yaml` |

## Restore

Copy files back to their original paths (see table above) and delete any
`destinationrule.yaml` in `app/backend/templates/`.
