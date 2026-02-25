#!/usr/bin/env bash
set -x
set -e

VPSADMINOS_OS_DIR="$WORKSPACE/vpsadmin/vpsadminos/os"
pushd "$VPSADMINOS_OS_DIR"

#for cfg in `ls -1 ./configs/nodes/os1.nix` ; do
#for cfg in `ls -1 ./configs/nodes/os2.nix` ; do
for node in "$@" ; do
	cfg="$VPSFDEV/nodes/$node.nix"
	mkdir -p result/nodes/$node
	VPSADMINOS_CONFIG="$cfg" nix build --impure \
		--out-link result/nodes/$node/qemu \
		..#qemu
#		--keep-going
#		--arg vpsadmin ../../vpsadmin \
done

popd
