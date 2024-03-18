#!/usr/bin/env bash
set -x
set -e

pushd "$WORKSPACE"/vpsadmin/vpsadminos/os

for node in $@ ; do
	cfg="$VPSFDEV/nodes/$node.nix"
	ip=$(nix-instantiate \
		--arg configuration "$cfg" \
		--eval \
		--attr config.networking.static.ip)
#		--arg vpsadmin ../../vpsadmin \
	addr="${ip:1}"
	addr="${addr%%/*}"
	mkdir -p result/nodes/$node
	nix-build \
		--arg configuration "$cfg" \
		--attr config.system.build.toplevel \
		--show-trace \
		--out-link result/nodes/$node/toplevel
#		--keep-going \
#		--arg vpsadmin ../../vpsadmin \
	system="$(readlink result/nodes/$node/toplevel)"
	nix copy --extra-experimental-features nix-command --to ssh://root@$addr "$system"
	ssh root@$addr "$system/bin/switch-to-configuration" switch
	#ssh root@$addr "$system/bin/switch-to-configuration" dry-activate
done

popd
