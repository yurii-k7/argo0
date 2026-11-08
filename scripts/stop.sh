#!/usr/bin/env bash
# Stop the cluster, keeping its state.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cluster_exists || die "cluster $PROFILE does not exist"
minikube stop -p "$PROFILE"
