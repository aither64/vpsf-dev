#!/usr/bin/env bash
set -x
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
VPSADMIN_SRC="${WORKSPACE_DIR}/vpsadmin/vpsadmin"
VPSADMINOS_SRC="${WORKSPACE_DIR}/vpsadmin/vpsadminos"
pushd "$ROOT_DIR"

for node in "$@"; do
	ip=$(nix eval --impure \
		--override-input vpsadmin "git+file://${VPSADMIN_SRC}" \
		--override-input vpsadminos "git+file://${VPSADMINOS_SRC}" \
		--raw "path:${ROOT_DIR}#nodeIps.${node}")
	addr="${ip%%/*}"
	mkdir -p result/nodes/$node
	nix build \
		--impure \
		--override-input vpsadmin "git+file://${VPSADMIN_SRC}" \
		--override-input vpsadminos "git+file://${VPSADMINOS_SRC}" \
		--show-trace \
		--out-link result/nodes/$node/toplevel \
		"path:${ROOT_DIR}#${node}-toplevel"
    # --cores 16 \
	system="$(readlink result/nodes/$node/toplevel)"
	nix copy --extra-experimental-features nix-command --to ssh://root@$addr "$system"
	ssh root@$addr "$system/bin/switch-to-configuration" switch
	#ssh root@$addr "$system/bin/switch-to-configuration" dry-activate
done

popd
