# Kubernetes Deployment Playbook

> One web app. Six strategies. Real-world settings.

A cloud-native project that demonstrates six mainstream Kubernetes deployment strategies on a single AKS cluster.

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white&style=plastic) ![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![Argo Rollouts](https://img.shields.io/badge/Argo%20Rollouts-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![Istio](https://img.shields.io/badge/Istio-7B42BC?style=for-the-badge&logo=istio&logoColor=white&style=plastic) ![Helm](https://img.shields.io/badge/helm-%230F1689.svg?style=for-the-badge&logo=helm&logoColor=white&style=plastic) ![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white&style=plastic) ![Microsoft Azure](https://custom-icon-badges.demolab.com/badge/Azure%20AKS-0089D6?logo=msazure&logoColor=white&style=plastic) ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white&style=plastic) ![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white&style=plastic)

- [Kubernetes Deployment Playbook](#kubernetes-deployment-playbook)
  - [Challenge](#challenge)
  - [Architecture](#architecture)
  - [Strategies Decision](#strategies-decision)
  - [Deployment Strategies](#deployment-strategies)
    - [Rolling Update](#rolling-update)
    - [Recreate](#recreate)
    - [Canary](#canary)
    - [Blue-Green](#blue-green)
    - [A/B Testing](#ab-testing)
    - [Shadow Deployment](#shadow-deployment)
  - [Documentation](#documentation)

---

## Challenge

Deployment is a critical process: it makes an application available in a live environment and delivers business value.

> How does a team select the right deployment method for a given requirement?

- This project
  - creates and deploys a **simple web application** in a real-world environment (Cluster + TLS + DNS),
  - compares **six common deployment methods**,
  - and concludes with a **deployment decision strategy**.

---

## Architecture

![diagram](./docs/img/infra_architecture.gif)
![diagram](./docs/img/kube_architecture.png)

---

## Strategies Decision

![pic](./docs/img/decision_tree.png)

---

## Deployment Strategies

### Rolling Update

- `Rolling Update`: Incrementally replaces old pods with new ones via `maxSurge` and `maxUnavailable`, keeping the service available throughout the rollout.
- **Pros**:
  - Zero downtime when readiness probes are configured correctly.
  - Native to Kubernetes — no additional controllers required.
  - Resource-efficient: no duplicate environment required.
- **Cons**:
  - Old and new versions coexist during rollout, so the app must be backward-compatible.
  - Rollback is another rolling update, not an instant switch.
- **Common use cases**:
  - Default choice for stateless services requiring continuous availability.
  - Routine, low-risk version upgrades in production.

- **ArgoCD UI**:

![rolling: argocd gif](./docs/img/deploy_rolling_argocd.gif)

> Gradually replaces older versions of an application with new ones.

- `curl` command to confirm downtime

![rolling: curl gif](./docs/img/deploy_rolling_curl.gif)

> Zero downtime from V1.0.0 to V1.1.0.

---

### Recreate

- `Recreate`: Terminates all existing pods before starting the new version, producing a brief service outage during the switch.
- **Pros**:
  - Simplest possible rollout — no version overlap to reason about.
  - Guarantees a clean cutover for workloads that cannot tolerate concurrent versions.
  - No extra compute overhead during the transition.
- **Cons**:
  - Incurs downtime between old-pod shutdown and new-pod readiness.
  - Unsuitable for user-facing services with availability SLAs.
- **Common use cases**:
  - Batch jobs, internal tools, or dev environments where downtime is acceptable.
  - Applications with breaking schema or protocol changes that forbid version overlap.

- **ArgoCD UI**:

![recreate: argocd gif](./docs/img/deploy_recreate_argocd.gif)

> Terminates all existing pods before starting the new version.

- `curl` command to confirm downtime

![recreate: curl gif](./docs/img/deploy_recreate_curl.gif)

> Experiences downtime from V2.0.0 to V2.1.0: "no healthy upstream".

---

### Canary

- `Canary Deployment`: Progressively shifts a small percentage of live traffic to the new version, increasing the weight in stages while monitoring health before full promotion.
- **Pros**:
  - Limits blast radius by exposing only a subset of users to the new version.
  - Enables data-driven promotion via automated analysis of real production metrics.
  - Fast rollback by shifting traffic weight back to the stable version.
- **Cons**:
  - Requires reliable metrics and analysis rules; otherwise promotion becomes manual.
  - Both versions must coexist safely, including shared state and downstream contracts.
- **Common use cases**:
  - High-risk releases where gradual, monitored exposure is required.
  - Services with strong observability and automated rollback criteria.

- **Argo Rollouts UI**:

![canary: argorollout gif](./docs/img/deploy_canary_argorollout.gif)

> Rollout controlled by setting weight.

- Traffic splitting

![canary: kiali gif](./docs/img/deploy_canary_kiali.gif)

> Traffic splits from 25% to 50% to 100%.

---

### Blue-Green

- `Blue-Green Deployment`: Runs two identical environments — blue (current) and green (new) — and cuts all traffic over at once after the green environment passes validation.
- **Pros**:
  - Instant cutover and equally instant rollback by flipping the router back to blue.
  - The new version can be fully validated on the preview lane before any user sees it.
  - No version mixing at the traffic layer — cleaner for stateful or contract-sensitive services.
- **Cons**:
  - Roughly doubles compute cost during the overlap window.
  - Database and schema changes still need to be backward-compatible across both lanes.

- **Argo Rollouts UI**:

![Blue-Green: argorollout gif](./docs/img/deploy_blue_green_argorollout.gif)

> 1. Manual promotion;
> 2. Traffic flip;
> 3. Old version auto-removed.

- Preview vs Active

![blue_green: preview](./docs/img/deploy_blue_green_preview.png)

> Upper: header-based request gets the preview version.
> Lower: active request gets the stable version.

![blue_green: flip](./docs/img/deploy_blue_green_flip.png)

> The moment traffic flips, from V4.0.0 to V4.1.0.

---

### A/B Testing

- `A/B Testing`
  - Definition: Routes specific user segments to different versions based on request attributes (headers, cookies, geography) rather than random weights, so behavior can be compared under matched conditions.
- **Use cases**:
  - Feature experimentation: measure conversion or engagement between variants.
  - Targeted rollout to beta users, internal testers, or a specific region.
  - Comparing UX or algorithm changes with statistically meaningful cohorts.

- **Argo Rollouts UI**:

![ab: argorollout gif](./docs/img/deploy_ab_argorollout.gif)

> Canary rollout ensures progressive deployment; Istio splits traffic 50/50 for A/B testing.

- Header-based preview vs stable

![ab: preview](./docs/img/deploy_ab_preview.png)

> Upper: header-based request hits the preview version.
> Lower: stable traffic hits both versions randomly.

---

### Shadow Deployment

- `Shadow (Traffic Mirroring)`: Mirrors a copy of live production traffic to the new version while responses are discarded, so the candidate is exercised with real workload without affecting users.
- **Use cases:**
  - Performance and load testing under real production traffic patterns.
  - Validating a rewritten or refactored service against the incumbent for behavioral parity.
  - Safely exercising risky changes (new database driver, dependency upgrade) with zero user impact.

- **Argo Rollouts UI**:

![shadow: argorollout](./docs/img/deploy_shadow_argorollout.png)

> Rollout of 2 pods to handle mirrored traffic.

![shadow: kiali](./docs/img/deploy_shadow_kiali.png)

> Stable:canary ~= 50/50 confirms traffic is being mirrored.

---

## Documentation

- [Web Application with Helm](docs/01-app.md)
- [Infrastructure as Code via Terraform](docs/02-infra.md)
- [ArgoCD](docs/03-argocd.md): add sync; terraform;
- [Network Layer by Istio](docs/04-istio.md)
