#!/usr/bin/env bash
# Build a new image version and bump the tag in deploy/kustomization.yaml. Does NOT commit or push.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
v="${1:-}"; [[ -n "$v" ]] || die "usage: $0 <version>"
"$ROOT/scripts/build-app.sh" "$v"
sed -i -E "s/^([[:space:]]*newTag:).*/\1 $v/" "$ROOT/deploy/kustomization.yaml"
log "deploy/kustomization.yaml now uses tag $v. Commit and push to deploy it:"
echo "    git commit -am 'Release $v' && git push"
