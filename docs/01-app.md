# Kubernetes Deployment Playbook: Web Application

[Back](../README.md)

- [Kubernetes Deployment Playbook: Web Application](#kubernetes-deployment-playbook-web-application)
  - [Goal](#goal)
  - [Scope](#scope)
  - [Backend](#backend)
  - [Frontend](#frontend)
  - [Development Phases](#development-phases)
    - [Phase 01 — Backend skeleton](#phase-01--backend-skeleton)
    - [Phase 02 — Backend API](#phase-02--backend-api)
    - [Phase 03 — Frontend](#phase-03--frontend)
  - [Key Commands](#key-commands)

---

## Goal

- Backend API served by nginx, packaged as a Helm chart.
- Frontend web served by nginx, packaged as a Helm chart, calling the backend.

## Scope

- **In scope:** Helm charts, manifests, app logic.
- **Out of scope:** k8s cluster provisioning, Argo CD install.
- **Deploy target:** Argo CD (later phase); Helm CLI during development.
- **Layout:**
  - `app/backend/`
  - `app/frontend/`

---

## Backend

Static responses served by nginx (no app runtime).

| Method | Path        | Response                                        |
| ------ | ----------- | ----------------------------------------------- |
| GET    | `/api/`     | `{"app": "demo app", "version": "V1.0.0"}` (v1) |
| GET    | `/api/`     | `{"app": "demo app", "version": "V2.0.0"}` (v2) |
| GET    | `/healthz/` | `ok`                                            |

Version is switched via image tag / chart value, not by routing.

---

## Frontend

- Static HTML served by nginx.
- On load, fetches `/api/` from backend and renders:
  - `App name: demo app`
  - `Version: V1.0.0`
- Backend URL is configurable via Helm values (ConfigMap → HTML/JS).

---

## Development Phases

### Phase 01 — Backend skeleton

- `helm create backend`, strip to:
  - `deployment.yaml`, `service.yaml`
  - `values.yaml` with `replicaCount: 1` only
- Deploy via Helm CLI.
- **Verify:** `helm status` healthy; `kubectl port-forward` shows nginx default page.

### Phase 02 — Backend API

- Add ConfigMap with `nginx.conf` + JSON responses for `/api/` and `/healthz/`.
- Deploy via Helm CLI.
- **Verify:** `port-forward` → `curl /api/` and `curl /healthz/` return expected payloads.

### Phase 03 — Frontend

- Copy backend chart as starting point.
- Add ConfigMap with `index.html` that fetches backend `/api/` and renders it.
- Deploy via Helm CLI.
- **Verify:** `port-forward` → browser shows app name + version pulled from backend.

---

## Key Commands

```sh
# ####################
# backend
# ####################
# generate manifests
helm template backend app/frontend
# lint check
helm lint app/backend

# install
helm upgrade -i backend app/backend -n backend --create-namespace

# confirm
helm status backend -n backend
kubectl get pods,svc -n backend
kubectl port-forward -n backend svc/backend 8080:80

# in another shell
curl -s http://localhost:8080/api/
# {"app":"demo app","version":"V1.0.0"}
curl -s http://localhost:8080/healthz/
# ok

# switch to v2 without editing values.yaml
helm upgrade -i backend app/backend -n backend --set api.version=V2.0.0
curl -s http://localhost:8080/api/
# {"app":"demo app","version":"V2.0.0"}


# ####################
# frontend
# ####################
# generate manifests
helm template frontend app/frontend
# lint check
helm lint app/frontend

# install
helm upgrade -i frontend app/frontend -n frontend --create-namespace

# confirm
helm status frontend -n frontend
kubectl rollout status deploy/frontend -n frontend
kubectl port-forward -n frontend svc/frontend 8081:80

curl -s http://localhost:8081/
# HTML page
curl -s http://localhost:8081/api/
# proxied to backend
curl -s http://localhost:8081/healthz/
# ok

# Cleanup between iterations
helm uninstall backend -n backend
helm uninstall frontend -n frontend
```
