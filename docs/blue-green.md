

```sh
# Watch the rollout
kubectl argo rollouts get rollout backend -n backend -w

# Production traffic still V1.1.13
curl -sk https://deploy.arguswatcher.net/api/

# Preview lane serves V1.2.0
curl -sk -H 'x-preview: true' https://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.1.14"}

# When happy, flip production
kubectl argo rollouts promote backend -n backend

# Production now V1.2.0 instantly
curl -sk https://deploy.arguswatcher.net/api/

# Old ReplicaSet stays for 120s (scaleDownDelaySeconds) — abort during this window rolls back instantly:
kubectl argo rollouts undo backend -n backend
```