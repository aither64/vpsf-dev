#!/usr/bin/env bash
set -x
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
VPSADMIN_SRC="${WORKSPACE_DIR}/vpsadmin/vpsadmin"
VPSADMINOS_SRC="${WORKSPACE_DIR}/vpsadmin/vpsadminos"
pushd "$ROOT_DIR"

for node in "$@"; do
  mkdir -p result/nodes/$node
  nix build \
    --impure \
    --override-input vpsadmin "git+file://${VPSADMIN_SRC}" \
    --override-input vpsadminos "git+file://${VPSADMINOS_SRC}" \
    --out-link result/nodes/$node/qemu \
    "path:${ROOT_DIR}#${node}-qemu"
done

popd
