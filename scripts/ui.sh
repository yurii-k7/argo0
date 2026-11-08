#!/usr/bin/env bash
# Port-forward the Argo CD UI to localhost:8080, log in the CLI, print the admin password.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tools
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
pid=$(port_forward "$ARGO_NS" argocd-server 8080 80)
trap 'kill $pid 2>/dev/null' EXIT INT TERM
for _ in $(seq 1 30); do curl -fsS -o /dev/null http://localhost:8080 2>/dev/null && break; sleep 1; done
pw=$(kc -n "$ARGO_NS" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
if [[ -n "$pw" ]]; then
  argocd login localhost:8080 --plaintext --username admin --password "$pw" >/dev/null && log "argocd CLI logged in"
else
  warn "argocd-initial-admin-secret not found (password changed or secret deleted)"
fi
echo "UI:       http://localhost:8080"
echo "User:     admin"
echo "Password: ${pw:-<unknown>}"
echo "Ctrl-C to stop the port-forward."
wait "$pid"
