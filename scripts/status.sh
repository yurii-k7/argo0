#!/usr/bin/env bash
# Overview of cluster, Argo CD and the sample app.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
log "minikube"; minikube status -p "$PROFILE" || true
log "Argo CD pods"; kc -n "$ARGO_NS" get pods
log "Application"; kc -n "$ARGO_NS" get app "$APP_NAME" 2>/dev/null || echo "(not found)"
log "App pods"; kc -n "$APP_NS" get pods 2>/dev/null || echo "(namespace $APP_NS not found)"
echo; echo "Tag in Git working copy: $(current_tag)"
