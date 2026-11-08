#!/usr/bin/env bash
# Delete the argo0 minikube profile. Leaves tools, .env and the Git repo alone.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
if [[ "${1:-}" != "--yes" ]]; then
  read -r -p "Delete minikube profile '$PROFILE' and everything in it? [y/N] " a
  [[ "$a" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi
if cluster_exists; then
  minikube delete -p "$PROFILE"
else
  log "Profile $PROFILE does not exist, nothing to do"
fi
