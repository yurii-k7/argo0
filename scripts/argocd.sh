#!/usr/bin/env bash
# Run the argocd CLI against the argo0 cluster. Usage: scripts/argocd.sh app get argo0-app
# Uses the CLI's own port-forward mode (a manually forwarded port is reset by the server
# when the CLI speaks gRPC to it), so ui.sh does not need to be running.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tools
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
COMMON=(--port-forward --port-forward-namespace "$ARGO_NS" --kube-context "$CTX" --plaintext)
if [[ "${1:-}" != "login" ]]; then
  pw=$(kc -n "$ARGO_NS" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
  [[ -z "$pw" ]] || argocd login "${COMMON[@]}" --username admin --password "$pw" >/dev/null
fi
exec argocd "${COMMON[@]}" "$@"
