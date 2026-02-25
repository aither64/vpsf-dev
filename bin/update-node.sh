#!/usr/bin/env bash
set -x
set -e

VPSADMINOS_OS_DIR="$WORKSPACE/vpsadmin/vpsadminos/os"
pushd "$VPSADMINOS_OS_DIR"

for node in "$@" ; do
	cfg="$VPSFDEV/nodes/$node.nix"
	ip=$(VPSADMINOS_CONFIG="$cfg" nix eval --impure --raw \
		--expr 'let sys = (builtins.getFlake (toString ../.)).lib.vpsadminosSystem { system = builtins.currentSystem; }; in sys.config.networking.static.ip')
#		--arg vpsadmin ../../vpsadmin \
	addr="${ip%%/*}"
	mkdir -p result/nodes/$node
	VPSADMINOS_CONFIG="$cfg" nix build --impure \
		--show-trace \
		--out-link result/nodes/$node/toplevel \
		..#toplevel
    # --cores 16 \
#		--keep-going \
#		--arg vpsadmin ../../vpsadmin \
	system="$(readlink result/nodes/$node/toplevel)"
	nix copy --extra-experimental-features nix-command --to ssh://root@$addr "$system"
	ssh root@$addr "$system/bin/switch-to-configuration" switch
	#ssh root@$addr "$system/bin/switch-to-configuration" dry-activate
done

popd
