#!/usr/bin/env bash
# Port-forward the sample app to localhost:8081.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
log "Sample app at http://localhost:8081 (Ctrl-C to stop)"
kc -n "$APP_NS" port-forward svc/argo0-app 8081:80
