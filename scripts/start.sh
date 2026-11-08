#!/usr/bin/env bash
# Restart a stopped cluster and wait for Argo CD.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_docker
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
minikube start -p "$PROFILE"
wait_argocd
log "Cluster is up"
