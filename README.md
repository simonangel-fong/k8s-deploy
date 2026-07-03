# Kubernetes Deployment Playbook

> One web app. Six strategies. Real-world settings.

A cloud-native project that demonstrates six mainstream Kubernetes deployment strategies on a single AKS cluster.

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white&style=plastic) ![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![Argo Rollouts](https://img.shields.io/badge/Argo%20Rollouts-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![Istio](https://img.shields.io/badge/Istio-7B42BC?style=for-the-badge&logo=istio&logoColor=white&style=plastic) ![Helm](https://img.shields.io/badge/helm-%230F1689.svg?style=for-the-badge&logo=helm&logoColor=white&style=plastic) ![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white&style=plastic) ![Microsoft Azure](https://custom-icon-badges.demolab.com/badge/Azure%20AKS-0089D6?logo=msazure&logoColor=white&style=plastic) ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white&style=plastic) ![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white&style=plastic)

- [Kubernetes Deployment Playbook](#kubernetes-deployment-playbook)
  - [Challenge](#challenge)
  - [Architecture](#architecture)
  - [Deployment Strategies](#deployment-strategies)
    - [Rolling Update](#rolling-update)
    - [Recreate](#recreate)
    - [Canary](#canary)
    - [Blue-Green](#blue-green)
    - [A/B Testing](#ab-testing)
    - [Shadow Deployment](#shadow-deployment)
  - [Strategies Decision](#strategies-decision)
  - [Documentation](#documentation)

---

## Challenge

Deployment is a critical process: it makes an application available in a live environment and delivers business value.

> How do team select the right deployment method for a given requirement?

- This project
  - creates and deploys a **simple web application** in a real-world environment (Cluster + TLS + DNS),
  - compares **six common deployment methods**,
  - and concludes a **deployment decistion strategy**.

---

## Architecture

```
recreate
rolling
canary
blue-green
a/b test
shadow
```

---

## Deployment Strategies

### Rolling Update

- `Rolling Update`
  - Definition: Gradually replaces old pods with new ones, using `maxSurge` and `maxUnavailable` so the service stays available throughout.
  - Tools: Kubernetes (native `Deployment` strategy)
  - Pros:
    - Zero downtime when readiness probes are configured correctly.
    - Built into Kubernetes: no additional controllers required.
  - Cons:
    - Old and new versions run simultaneously, so the app must be backward-compatible.
    - Rollback is another rolling update, not an instant switch.

- **ArgoCD UI**:

![rolling: argocd gif](./docs/img/rolling_argocd.gif)

> gradually replaces older versions of an application new ones

- curl command to confirm downtime

![rolling: curl gif](./docs/img/rolling_curl.gif)

> zero downtime from V1.0.0 to V1.1.0

---

### Recreate

- `Recreate`
  - Definition: Terminates all existing pods before starting the new version, resulting in a brief service outage during the switch.
  - Tools: Kubernetes (native `Deployment` strategy)
  - Pros:
    - Simplest possible rollout: no version overlap to reason about.
    - Guarantees a clean cutover for workloads that cannot tolerate concurrent versions.
  - Cons:
    - Incurs downtime between the shutdown and readiness of the new pods.
    - Not suitable for user-facing production services with availability SLAs.

- **ArgoCD UI**:

![recreate: argocd gif](./docs/img/recreate_argocd.gif)

> Terminates all existing pods before starting the new version

- curl command to confirm downtime

![recreate: curl gif](./docs/img/recreate_curl.gif)

> experience downtime from V2.0.0 to V2.1.0: "no healthy upstream"

---

### Canary

- `Canary Deployment`
  - Definition: Progressively shifts a small percentage of live traffic to the new version, increasing the weight in stages while monitoring health before promoting to 100%.
  - Tools: Argo Rollouts + Istio (weighted `VirtualService`)
  - Benefits:
    - Limits blast radius by exposing only a subset of users to the new version.
    - Enables data-driven promotion via automated analysis of real production metrics.
    - Rollback is fast — shift the weight back to the stable version.
  - Limitations:
    - Requires reliable metrics and analysis rules to be truly automated; otherwise it becomes manual.
    - Both versions must coexist safely, including shared state and downstream contracts.

- **Argo Rollouts UI**:

![canary: argorollout gif](./docs/img/canary_argorollout.gif)

- Traffic splitting

![canary: kiali gif](./docs/img/canary_kiali01.gif)
![canary: kiali gif](./docs/img/canary_kiali02.gif)
![canary: kiali gif](./docs/img/canary_kiali03.gif)

---

### Blue-Green

- `Blue-Green Deployment`
  - Definition: Runs two identical environments — blue (current) and green (new) — and cuts all traffic over at once after the green environment passes validation.
  - Tools: Argo Rollouts + Istio (active/preview services)
  - Benefits:
    - Instant cutover and equally instant rollback by flipping the router back to blue.
    - The new version can be fully validated on the preview lane before any user sees it.
    - No version mixing at the traffic layer — cleaner for stateful or contract-sensitive services.
  - Limitations:
    - Roughly doubles compute cost during the overlap window.
    - Database and schema changes still need to be backward-compatible across both lanes.

![Blue-Green: argorollout gif](./docs/img/blue_green_argorollout.gif)

- Traffic splitting

![Blue-Green: kiali gif](./docs/img/blue_green_kiali01.gif)
![Blue-Green: kiali gif](./docs/img/blue_green_kiali02.gif)
![Blue-Green: kiali gif](./docs/img/blue_green_kiali03.gif)

---

### A/B Testing

- `A/B Testing`
  - Definition: Routes specific user segments to different versions based on request attributes (headers, cookies, geography) rather than random weights, so behavior can be compared under matched conditions.
  - Tools: Argo Rollouts + Istio (header-matched `VirtualService`)
  - Use cases:
    - Feature experimentation — measure conversion or engagement between variants.
    - Targeted rollout to beta users, internal testers, or a specific region.
    - Comparing UX or algorithm changes with statistically meaningful cohorts.

![ab-test: argorollout gif](./docs/img/ab_test_argorollout.gif)

- Traffic splitting

![ab-test: kiali gif](./docs/img/ab_test_kiali01.gif)
![ab-test: kiali gif](./docs/img/ab_test_kiali02.gif)
![ab-test: kiali gif](./docs/img/ab_test_kiali03.gif)

![ab-test: curl gif](./docs/img/ab_test_curl.gif)

---

### Shadow Deployment

- `Shadow (Traffic Mirroring)`
  - Definition: Mirrors a copy of live production traffic to the new version while responses are discarded, so the candidate is exercised with real workload without affecting users.
  - Tools: Argo Rollouts + Istio (`mirror` and `mirrorPercentage` on `VirtualService`)
  - Use cases:
    - Performance and load testing under real production traffic patterns.
    - Validating a rewritten or refactored service against the incumbent for behavioral parity.
    - Safely exercising risky changes (new database driver, dependency upgrade) with zero user impact.

![shadow: argorollout gif](./docs/img/shadow_argorollout.gif)

- Traffic splitting

![shadow: kiali gif](./docs/img/shadow_kiali01.gif)
![shadow: kiali gif](./docs/img/shadow_kiali02.gif)
![shadow: kiali gif](./docs/img/shadow_kiali03.gif)

![shadow: curl gif](./docs/img/shadow_curl.gif)

---

## Strategies Decision

The decision tree this repo follows:

```txt
Does the workload require zero concurrent versions?
├── Yes → Recreate. Accept downtime.
└── No → Do you need pod-lifecycle only, or traffic control?
    ├── Pod-lifecycle only → RollingUpdate.
    └── Traffic control → Argo Rollouts:
        ├── Instant rollback matters most        → Blue-Green
        ├── Progressive real-user exposure       → Canary
        ├── Compare versions at parity           → A/B (header + weight)
        └── Validate without exposing users      → Shadow (mirror)
```

---

## Documentation

- [Web Application with Helm](docs/01-app.md)
- [Infrastructure as Code via Terraform](docs/02-infra.md)
- [ArgoCD](docs/03-argocd.md): add sync; terraform; 
- [Network Layer by Istio](docs/04-istio.md)
