#!/usr/bin/env bash
set -x
set -e
#for cfg in `ls -1 ./configs/nodes/os1.nix` ; do
#for cfg in `ls -1 ./configs/nodes/os2.nix` ; do
for node in $@ ; do
	cfg="./configs/nodes/$node.nix"
	mkdir -p result/nodes/$node
	nix-build \
		--arg configuration "$cfg" \
		--attr config.system.build.runvm \
		--out-link result/nodes/$node/qemu \
		--keep-going
#		--arg vpsadmin ../../vpsadmin \
done
