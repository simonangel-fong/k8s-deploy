goal:
create github pages with html, css, js

github pages

- file path: /docs/
- url: https://simonangel-fong.github.io/k8s-deploy/

style reference

- https://eks-benchmark.arguswatcher.net/
- https://gitops.arguswatcher.net/
- https://simonangel-fong.github.io/multi-tenant-cluster-eks/

---

phase 00 — scaffold

- create asset dirs: docs/assets/{css,js,img}
- create docs/index.html: Bootstrap 5 dark theme, hello-world stub
- update GitHub Actions workflow:
  - trigger: push to master, path docs/\*\*
  - deploy: actions/deploy-pages from /docs root
- verify: page loads at GitHub Pages URL

phase 01 — outline

- define page sections (see below)
- decide title, one-line goal, and key content per section (no copy yet)

refernce: project README.md
sections:

- Hero: project title, tagline, CTA button (GitHub link)
- Business Challenge & Solution
- Architecture: infra diagram + k8s diagram
- Rolling Update
- Recreate
- Canary
- Blue-Green
- A/B Testing
- Shadow Deployment
- Summary (Strategies Decision)

phase 02 — content development

per section, produce:

- final copy (title, description, captions)
- captured screenshots / GIFs from docs/img/
- responsive layout (Bootstrap grid, cards, tabs or accordion for strategies)

assets to use:

- docs/img/infra_architecture.gif, kube_architecture.png
- docs/img/decision_tree.png
- docs/img/deploy*\*.gif / deploy*\*.png (one per strategy)

phase 03 — interactivity

- smooth-scroll nav with active-section highlighting
- strategy cards: hover effect, expand/collapse details
- image lightbox or modal for diagrams (if needed)
- all JS in docs/assets/js/main.js; no external JS beyond Bootstrap bundle

phase 04 — finalize

- review and refactor html, css, js
- polish layout, spacing, dark theme consistency
- validate: W3C HTML check, no console errors, mobile responsive (375px+)
- check all images load and GIFs play correctly on the live page

---

- Business Challenge & Solution
  - goal: state the challenge in terms o business instead of tech
  - mode: challenge & response
  - 1st sentence: state the deployment impact on business
    - give necessary context
  - 2nd sentence: state the challenge
    - present it in plain english, non-tech can understand
    - using wh-question style
  - 3rd sentence: state solution provided by current project
