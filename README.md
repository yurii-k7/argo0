# argo0

A local playground for learning [Argo CD](https://argo-cd.readthedocs.io/) on minikube.
One script creates everything, one script removes it, and a set of exercises walks through
the core GitOps workflow.

> **Status: implemented.** The tool installer, app image and manifests are tested. The full
> bootstrap against minikube is untested until the repo is pushed; see [Build order](#build-order).

## How it works

```text
 you ── git push ──> GitHub (REPO_URL)
                        ^
                        │ Argo CD polls deploy/
                        │
 ┌─ minikube profile "argo0" ───────────────────────┐
 │  namespace argocd    Argo CD (Helm chart)        │
 │        │ syncs                                   │
 │        v                                         │
 │  namespace demo      argo0-app (2 replicas)      │
 │                      image built inside minikube │
 └──────────────────────────────────────────────────┘
```

Git is the source of truth for what runs in the cluster. The image is built locally and loaded
straight into minikube, so no container registry is needed. Git only decides which image tag runs.

## Goals

The playground covers these Argo CD basics:

- Installing Argo CD with a pinned Helm chart.
- Defining an `Application` that tracks a path in Git.
- Automatic sync, self-heal and pruning.
- Reading sync status and health in the UI and CLI.
- Releasing and rolling back by changing Git.

These topics are out of scope for the first version and are natural next steps:

- `ApplicationSet` with dev, staging and prod overlays.
- App of Apps, and Argo CD managing its own install.
- Sync waves and PreSync/PostSync hooks.
- `AppProject` restrictions and RBAC.

## Prerequisites

Developed on Linux under WSL2 with:

| Requirement | Notes |
| --- | --- |
| Docker | Must be running. It is minikube's driver. |
| minikube | Already installed in `~/.local/bin`. |
| git, curl | Used by the scripts. |
| GitHub repo | Must exist at `REPO_URL` and have `deploy/` pushed to `main` before bootstrap. |
| About 4 CPUs and 8 GB RAM | Reserved for the minikube node. |

`kubectl`, `helm` and the `argocd` CLI are installed automatically by `scripts/install-tools.sh`.
Nothing needs `sudo`.

## Quick start

```bash
cp .env.example .env              # then edit REPO_URL if needed
git init -b main && git add -A && git commit -m "Initial commit"
git remote add origin "$(grep ^REPO_URL= .env | cut -d= -f2-)"
git push -u origin main

./scripts/bootstrap.sh            # creates the cluster, Argo CD and the app
./scripts/ui.sh                   # opens access to the UI, leave it running
```

Then open <http://localhost:8080> and log in as `admin` with the password printed by `ui.sh`.

## Configuration

Settings live in two files, and every script loads both.

`.env` holds per-machine settings and is not committed:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `REPO_URL` | yes | none | Git URL that Argo CD watches. HTTPS for public, SSH for private. |
| `SSH_KEY` | for SSH URLs | none | Path to the private key for a private repo. |
| `TARGET_REVISION` | no | `main` | Branch Argo CD tracks. |

For a private repo, use a read-only GitHub deploy key rather than your personal key, because
bootstrap stores the key in a Kubernetes secret in the cluster.

`versions.env` is committed and pins everything that affects reproducibility: the kubectl, helm
and argocd CLI versions, the Kubernetes version, the `argo-cd` Helm chart version, and the minikube
CPU and memory settings. The `argocd` CLI version should match the Argo CD version that the chart
ships.

## Scripts

All scripts are safe to re-run and only ever target the `argo0` minikube profile and kube context.
They never touch your other clusters or change your current context.

| Script | What it does |
| --- | --- |
| `scripts/bootstrap.sh` | Full setup from nothing. Details below. |
| `scripts/teardown.sh` | Deletes the `argo0` profile after a confirmation. `--yes` skips it. |
| `scripts/stop.sh` | Stops the cluster and keeps its state. |
| `scripts/start.sh` | Restarts a stopped cluster and waits for Argo CD. |
| `scripts/status.sh` | Shows cluster state, Argo CD pods, Application sync and health, and app pods. |
| `scripts/ui.sh` | Port-forwards the UI to `localhost:8080` and prints the admin password. |
| `scripts/argocd.sh <args>` | Runs the `argocd` CLI against this cluster, logging in as admin. Works without `ui.sh`. |
| `scripts/app.sh` | Port-forwards the sample app to `localhost:8081`. |
| `scripts/refresh.sh` | Makes Argo CD check Git now rather than waiting for the next poll. |
| `scripts/build-app.sh <version>` | Builds `argo0-app:<version>` inside minikube. |
| `scripts/release.sh <version>` | Runs `build-app.sh`, then updates the image tag in `deploy/kustomization.yaml`. |
| `scripts/install-tools.sh` | Installs pinned, checksum-verified CLIs into `~/.local/bin`. |
| `scripts/lib.sh` | Shared helpers. Not run directly. |

`release.sh` deliberately does not commit or push. Doing that yourself is the step that triggers
the deployment, and it is the point of the exercise.

`teardown.sh` leaves the CLI tools in place, and leaves `.env` and the Git repo untouched.

### What bootstrap does

1. Loads the config and checks that Docker is running and that `REPO_URL` and its branch are reachable.
2. Runs `install-tools.sh`.
3. Starts minikube with the `docker` driver, using the `argo0` profile.
4. Installs Argo CD with `helm upgrade --install`, using `argocd/values.yaml`, and waits until it is ready.
5. For an SSH `REPO_URL`, creates the repository secret from `SSH_KEY`.
6. Builds the image for the tag currently set in `deploy/kustomization.yaml`.
7. Renders `argocd/application.yaml.tmpl` with `REPO_URL` and `TARGET_REVISION`, then applies it.
8. Waits for the Application to be `Synced` and `Healthy`, then prints the next steps.

## Layout

```text
argo0/
├── README.md
├── .env.example
├── .gitignore
├── versions.env                  # pinned versions and cluster size
├── scripts/                      # see the table above
├── app/
│   ├── Dockerfile                # takes APP_VERSION as a build arg
│   └── server.py                 # standard library only, shows its version, serves /healthz
├── deploy/                       # the path Argo CD watches
│   ├── kustomization.yaml        # the image tag lives here
│   ├── deployment.yaml
│   └── service.yaml
└── argocd/
    ├── values.yaml               # Helm values
    └── application.yaml.tmpl     # the Application, rendered at bootstrap
```

## Design decisions

- **Dedicated profile.** Using `-p argo0` keeps the playground separate from any other minikube cluster.
- **UI over port-forward.** Under WSL2 with the Docker driver, NodePorts are awkward to reach from
  Windows, while a forwarded `localhost` port normally just works.
- **CLI through its own port-forward.** The server resets raw gRPC connections arriving over a
  `kubectl port-forward`, so `argocd.sh` uses the CLI's built-in `--port-forward` mode instead.
- **Plain HTTP inside the playground.** `server.insecure` is on, which avoids self-signed certificate
  warnings. This is for local use only.
- **Lean install.** Dex and notifications are disabled because nothing here uses them.
- **Faster polling.** `timeout.reconciliation` is set to `60s`, down from about 3 minutes. GitHub
  webhooks can't reach a local cluster, so polling or `refresh.sh` is how changes get noticed.
- **Sync policy.** Automated with `prune` and `selfHeal`, and `CreateNamespace=true`.
- **Immutable tags with `imagePullPolicy: Never`.** A tag that was never built fails immediately with
  `ErrImageNeverPull`, rather than a confusing failed pull from Docker Hub.

Images exist only inside the cluster. After a teardown, bootstrap rebuilds only the tag currently
in Git, so older versions are gone.

## Exercises

Keep `./scripts/ui.sh` running in another terminal if you want the UI. The CLI exercises use
`scripts/argocd.sh` and do not need it.

1. **Look around.** Open the app in the UI and find its resource tree, sync status and health.
   Run `./scripts/argocd.sh app get argo0-app` and compare.
2. **Release through Git.** Run `./scripts/release.sh 1.1.0`, then commit and push. Run
   `./scripts/refresh.sh` and watch the rolling update. Confirm the new version with `./scripts/app.sh`.
3. **Self-heal.** Run `kubectl --context argo0 -n demo scale deploy argo0-app --replicas=5` and watch
   Argo CD put it back to the replica count in Git.
4. **See drift.** Turn off auto-sync with `./scripts/argocd.sh app set argo0-app --sync-policy none`, repeat the
   scale command, then inspect `./scripts/argocd.sh app diff argo0-app`. Sync by hand and turn auto-sync back on.
5. **Prune.** Add a ConfigMap to `deploy/` and push it. Remove it and push again, then watch Argo CD delete it.
6. **Ship a broken release.** Set the tag in `deploy/kustomization.yaml` to a version that was never
   built, then push. Watch the app go from `Progressing` to `Degraded`, and notice the old pods keep serving.
7. **Roll back.** Use `git revert` and push, which is the GitOps way. Then compare with
   `./scripts/argocd.sh app rollback argo0-app`, which requires auto-sync to be off and leaves Git and the cluster disagreeing.
8. **Start over.** Run `./scripts/teardown.sh`, then `./scripts/bootstrap.sh`, and confirm the state
   comes back from Git alone.

## Build order

- [x] `versions.env`, `scripts/lib.sh`, `scripts/install-tools.sh` (tested)
- [x] Sample app, `scripts/build-app.sh`, `deploy/` manifests (image and kustomize build tested)
- [x] `argocd/values.yaml`, `argocd/application.yaml.tmpl` (Helm render tested)
- [x] `scripts/bootstrap.sh`, `scripts/teardown.sh`
- [x] `scripts/start.sh`, `stop.sh`, `status.sh`, `ui.sh`, `app.sh`, `refresh.sh`, `release.sh`
- [ ] First push to GitHub, then a full bootstrap, exercises and teardown run
