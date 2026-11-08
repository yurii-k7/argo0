#!/usr/bin/env bash
# Expose the sample app on a local URL through the minikube node (NodePort service).
# Unlike `kubectl port-forward`, this is not tied to one pod: kube-proxy balances across ready
# pods, so killing a pod does not interrupt access.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cluster_exists || die "cluster $PROFILE does not exist; run scripts/bootstrap.sh"
type=$(kc -n "$APP_NS" get svc argo0-app -o jsonpath='{.spec.type}' 2>/dev/null || true)
[[ "$type" == "NodePort" ]] || die "service argo0-app is '${type:-missing}', expected NodePort. Commit and push deploy/service.yaml, then ./scripts/refresh.sh"
log "Sample app URL is printed below (Ctrl-C to stop)"
exec minikube service argo0-app -n "$APP_NS" -p "$PROFILE" --url
