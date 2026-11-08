#!/usr/bin/env bash
# Build argo0-app:<version> inside minikube (works with any container runtime).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
v="${1:-}"; [[ -n "$v" ]] || die "usage: $0 <version>"
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
log "Building argo0-app:$v inside minikube"
minikube -p "$PROFILE" image build -t "argo0-app:$v" --build-opt="opt=build-arg:APP_VERSION=$v" "$ROOT/app"
