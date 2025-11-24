# Documentation Workflow

The Hydra-V documentation uses [mike](https://github.com/jimporter/mike) to manage multiple versions (e.g., `1.0`, `dev`). This process is automated via GitHub Actions.

## 1. Daily Development (`dev`)

Any commit pushed to the `main` branch automatically triggers a deployment to the **dev** version.

* **URL:** `.../Hydra-V/dev/`
* **Behavior:** This version is mutable. New pushes overwrite the previous `dev` content.

## 2. Publishing a Release (`vX.X`)

To "freeze" the documentation for a specific processor version (e.g., when Version 1.0 RTL is complete), use **Git Tags**. The CI pipeline detects tags starting with `v` and creates a permanent documentation snapshot.

**Steps to release:**

1. Commit your final changes.
2. Tag the commit with the version number (e.g., `v1.0`).
3. Push the tag to GitHub.

```bash
# Example: Releasing Version 1.0
git commit -am "Finalize RTL and Docs for v1.0"
git tag v1.0
git push origin v1.0
```

**Results:**

* A new folder `/1.0/` is created in the documentation.
* The `latest` alias is updated to point to `1.0`.
* The default landing page is switched to `1.0`.
