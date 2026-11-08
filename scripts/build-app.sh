#!/usr/bin/env bash
# Build argo0-app:<version> inside minikube's Docker daemon.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
v="${1:-}"; [[ -n "$v" ]] || die "usage: $0 <version>"
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
log "Building argo0-app:$v inside minikube"
( eval "$(minikube -p "$PROFILE" docker-env)"
  docker build -q --build-arg "APP_VERSION=$v" -t "argo0-app:$v" "$ROOT/app" )
