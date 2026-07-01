# ArgoCD Bootstrap Plan

ArgoCD itself is installed by Terraform ([infra/08_argocd.tf](infra/08_argocd.tf)).
This document covers what gets deployed *onto* ArgoCD after the cluster is up.

Source repo: <https://github.com/simonangel-fong/k8s-deploy> (branch: `master`)

---

## Phase 0 — Access ArgoCD

Port-forward the server, retrieve the initial admin password, log in.

## Phase 1 — Root App (App-of-Apps)

Create `argocd/01-root.yaml` in the source repo and apply it once. The root
Application watches `argocd/apps/` (empty for now) and will pick up children as
later phases add them.

## Phase 2 — Istio

Add child Applications under `argocd/apps/` for `istio-base`, `istiod`, and
`istio-gateway`, ordered by sync wave.

## Phase 3 — Argo Rollouts

Add a child Application under `argocd/apps/` for `argo-rollouts`.

## Phase 4 — Demo Apps & Rollout Strategies

Add child Applications for `demo-backend` and `demo-frontend`, then demonstrate
canary, blue/green, A/B, and shadow strategies.

## Teardown

Delete the root Application, then `terraform destroy` the infra.

---

## Dev

```sh
kubectl apply -f argocd/00-root.yaml
```