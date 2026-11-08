#!/usr/bin/env bash
# Create the minikube cluster, install Argo CD and register the sample Application.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

require_env
require_docker
log "Checking $REPO_URL ($TARGET_REVISION)"
if [[ "$REPO_URL" == git@* || "$REPO_URL" == ssh://* ]]; then
  [[ -f "${SSH_KEY:-}" ]] || die "SSH_KEY must point to an existing private key for an SSH REPO_URL"
  GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
    git ls-remote --exit-code "$REPO_URL" "$TARGET_REVISION" >/dev/null \
    || die "cannot reach $REPO_URL branch $TARGET_REVISION"
else
  GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$REPO_URL" "$TARGET_REVISION" >/dev/null \
    || die "cannot reach $REPO_URL branch $TARGET_REVISION (does it exist, is it public and pushed?)"
fi

"$ROOT/scripts/install-tools.sh"
require_tools

log "Starting minikube profile $PROFILE"
minikube start -p "$PROFILE" --driver=docker --cpus="$MINIKUBE_CPUS" --memory="$MINIKUBE_MEMORY" \
  --kubernetes-version="$K8S_VERSION"
kc get nodes >/dev/null

log "Installing Argo CD chart $ARGOCD_CHART_VERSION"
hm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
hm upgrade --install argocd argo/argo-cd --version "$ARGOCD_CHART_VERSION" \
  --namespace "$ARGO_NS" --create-namespace -f "$ROOT/argocd/values.yaml" --wait --timeout 10m
wait_argocd

if [[ "$REPO_URL" == git@* || "$REPO_URL" == ssh://* ]]; then
  log "Registering SSH repository credentials"
  kc -n "$ARGO_NS" create secret generic argo0-repo \
    --from-literal=type=git --from-literal=url="$REPO_URL" \
    --from-file=sshPrivateKey="$SSH_KEY" --dry-run=client -o yaml \
    | kc label --local -f - argocd.argoproj.io/secret-type=repository -o yaml \
    | kc apply -f -
fi

"$ROOT/scripts/build-app.sh" "$(current_tag)"

log "Applying Application $APP_NAME"
export REPO_URL TARGET_REVISION
envsubst '${REPO_URL} ${TARGET_REVISION}' < "$ROOT/argocd/application.yaml.tmpl" | kc apply -f -

log "Waiting for the app to be Synced and Healthy"
for _ in $(seq 1 90); do
  s=$(kc -n "$ARGO_NS" get app "$APP_NAME" -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null || true)
  [[ "$s" == "Synced/Healthy" ]] && break
  sleep 4
done
[[ "${s:-}" == "Synced/Healthy" ]] || { warn "app is '${s:-unknown}'; see scripts/status.sh"; exit 1; }

cat <<MSG

Done. Next:
  ./scripts/ui.sh     Argo CD UI at http://localhost:8080 (keep it running)
  ./scripts/app.sh    sample app at http://localhost:8081
  ./scripts/status.sh overview
MSG
