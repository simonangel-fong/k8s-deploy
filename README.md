# argocd-argorollout-istio

kubectl -n cert-manager create secret generic cloudflare-api-token \
 --from-literal=api-token='PASTE_YOUR_TOKEN_HERE'

- Code clean
- Docs
- README
- capture

```txt
Does the workload require zero concurrent versions?
├── Yes → Recreate. Accept downtime.
└── No → Do you need pod-lifecycle only, or traffic control?
    ├── Pod-lifecycle only → RollingUpdate. Done.
    └── Traffic control → Argo Rollouts, then choose by need:
        ├── Instant rollback matters most → Blue-Green
        ├── Progressive real-user exposure → Canary (with or without analysis)
        ├── Compare versions at parity → A/B (header-pin + weight)
        └── Validate without exposing users → Shadow
```
