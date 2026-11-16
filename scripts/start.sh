#!/usr/bin/env bash
# Restart a stopped cluster and wait for Argo CD.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_docker
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
minikube start -p "$PROFILE"
if ! kc get ns "$ARGO_NS" >/dev/null 2>&1; then
  warn "namespace $ARGO_NS missing (cluster was recreated?); running bootstrap to install Argo CD"
  exec "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh"
fi
wait_argocd
log "Cluster is up"
