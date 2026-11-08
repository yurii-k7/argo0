#!/usr/bin/env bash
# Port-forward the Argo CD UI to localhost:8080 and print the admin password.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tools
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
kc -n "$ARGO_NS" port-forward svc/argocd-server 8080:80 >/dev/null 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null' EXIT INT TERM
for _ in $(seq 1 30); do curl -s -o /dev/null http://localhost:8080 && break; sleep 1; done
pw=$(kc -n "$ARGO_NS" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
[[ -n "$pw" ]] || warn "argocd-initial-admin-secret not found (password changed or secret deleted)"
echo "UI:       http://localhost:8080"
echo "User:     admin"
echo "Password: ${pw:-<unknown>}"
echo "Ctrl-C to stop the port-forward."
wait "$pid"
