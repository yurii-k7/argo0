#!/usr/bin/env bash
# Install pinned, checksum-verified kubectl, helm and argocd into ~/.local/bin (no sudo).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BIN="$HOME/.local/bin"; mkdir -p "$BIN"
ARCH=$(uname -m); case "$ARCH" in x86_64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; *) die "unsupported arch $ARCH";; esac
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

if [[ "$(kubectl version --client 2>/dev/null | grep -o "$KUBECTL_VERSION" | head -1)" != "$KUBECTL_VERSION" ]]; then
  log "Installing kubectl $KUBECTL_VERSION"
  u=https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$ARCH/kubectl
  curl -fsSL "$u" -o "$TMP/kubectl"
  echo "$(curl -fsSL "$u.sha256")  $TMP/kubectl" | sha256sum -c - >/dev/null
  install -m 0755 "$TMP/kubectl" "$BIN/kubectl"
else log "kubectl $KUBECTL_VERSION already installed"; fi

if [[ "$(helm version --short 2>/dev/null)" != "$HELM_VERSION"* ]]; then
  log "Installing helm $HELM_VERSION"
  f=helm-$HELM_VERSION-linux-$ARCH.tar.gz
  curl -fsSL "https://get.helm.sh/$f" -o "$TMP/$f"
  want=$(curl -fsSL "https://get.helm.sh/$f.sha256sum" | awk '{print $1}')
  echo "$want  $TMP/$f" | sha256sum -c - >/dev/null
  tar -xzf "$TMP/$f" -C "$TMP"
  install -m 0755 "$TMP/linux-$ARCH/helm" "$BIN/helm"
else log "helm $HELM_VERSION already installed"; fi

if [[ "$(argocd version --client --short 2>/dev/null)" != *"${ARGOCD_CLI_VERSION#v}"* ]]; then
  log "Installing argocd $ARGOCD_CLI_VERSION"
  base=https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_CLI_VERSION
  curl -fsSL "$base/argocd-linux-$ARCH" -o "$TMP/argocd-linux-$ARCH"
  want=$(curl -fsSL "$base/cli_checksums.txt" | awk -v f="argocd-linux-$ARCH" '$2==f{print $1}')
  [[ -n "$want" ]] || die "no checksum found for argocd-linux-$ARCH"
  echo "$want  $TMP/argocd-linux-$ARCH" | sha256sum -c - >/dev/null
  install -m 0755 "$TMP/argocd-linux-$ARCH" "$BIN/argocd"
else log "argocd $ARGOCD_CLI_VERSION already installed"; fi

command -v minikube >/dev/null || die "minikube not found; install it first (https://minikube.sigs.k8s.io)."
case ":$PATH:" in *":$BIN:"*) ;; *) warn "$BIN is not in your PATH";; esac
log "Tools ready"
