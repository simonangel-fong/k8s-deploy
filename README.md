# argocd-argorollout-istio

kubectl -n cert-manager create secret generic cloudflare-api-token \
  --from-literal=api-token='PASTE_YOUR_TOKEN_HERE'


- Delpyment
  - backend-canary-multsvc
  - backend-canary-multdest
  - backend-blue-green
  - backend-ab
  - backend-canary-shadow
- Code clean
- Docs
- README
- capture
