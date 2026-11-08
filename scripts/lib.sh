#!/usr/bin/env bash
# Shared helpers. Source this, do not run it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

PROFILE=argo0
CTX=argo0
APP_NAME=argo0-app
APP_NS=demo
ARGO_NS=argocd

# shellcheck disable=SC1091
source "$ROOT/versions.env"
if [[ -f "$ROOT/.env" ]]; then
  set -a; source "$ROOT/.env"; set +a
fi
TARGET_REVISION="${TARGET_REVISION:-main}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# Always target the argo0 context, never the user's current one.
kc() { kubectl --context "$CTX" "$@"; }
hm() { helm --kube-context "$CTX" "$@"; }

require_env() { [[ -n "${REPO_URL:-}" ]] || die "REPO_URL is not set. Copy .env.example to .env and edit it."; }
require_docker() { docker info >/dev/null 2>&1 || die "Docker is not running."; }
require_tools() {
  local t
  for t in minikube kubectl helm argocd; do
    command -v "$t" >/dev/null || die "$t not found. Run scripts/install-tools.sh"
  done
}
cluster_exists() { minikube profile list -o json 2>/dev/null | grep -q "\"Name\":\"$PROFILE\""; }

# Poll until the argocd-server deployment is available.
wait_argocd() {
  kc -n "$ARGO_NS" rollout status deploy/argocd-server --timeout=300s
  kc -n "$ARGO_NS" rollout status deploy/argocd-repo-server --timeout=300s
  kc -n "$ARGO_NS" rollout status statefulset/argocd-application-controller --timeout=300s
}

# Current image tag in deploy/kustomization.yaml.
current_tag() { sed -nE 's/^[[:space:]]*newTag:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/p' "$ROOT/deploy/kustomization.yaml"; }

# Port-forward a service in the background; echo the PID.
port_forward() { # ns svc local remote
  kc -n "$1" port-forward "svc/$2" "$3:$4" >/dev/null 2>&1 &
  echo $!
}
