#!/usr/bin/env bash
# Ask Argo CD to re-read Git now instead of waiting for the next poll.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
kc -n "$ARGO_NS" annotate app "$APP_NAME" argocd.argoproj.io/refresh=hard --overwrite
