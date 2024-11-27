{ config, pkgs, lib, ... }:
let
  inherit (lib) concatStringsSep mapAttrsToList;

  netifs = {
    oneg0 = "00:60:2f:38:ad:af";
  };

  renameNetif = mac: newName: ''
    oldName=$(ip -o link | grep "${mac}" | awk -F': ' '{print $2}')

    if [ -n "$oldName" ]; then
      echo "  $oldName -> ${newName}"
      ip link set dev "$oldName" name "${newName}"
    else
      echo "  interface with ${mac} not found"
    fi

    oldName=
  '';
in {
  boot.qemu.network.bridge.mac = netifs.oneg0;

  boot.initrd.kernelModules = [
    "lockd"
    "netfs"
    "nfsv4"
    "sunrpc"
  ];

  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.nfs-utils}/bin/mount.nfs
  '';

  boot.crashDump = {
    enable = true;
    commands = ''
      date=$(date +%Y%m%dT%H%M%S)
      server="172.16.0.8:/storage/vpsfree.cz/crashdump"
      mountpoint="/mnt/nfs"
      target="$mountpoint/${config.networking.hostName}/$date"

      echo "Renaming network interfaces"
      ${concatStringsSep "\n" (mapAttrsToList (name: mac: renameNetif mac name) netifs)}

      echo "Configuring network"
      ip addr add 172.16.106.42/24 dev oneg0
      ip link set oneg0 up
      ip route add default via 172.16.106.1 dev oneg0

      echo "Mounting NFS"
      mkdir -p "$mountpoint"
      mount.nfs -v -o vers=4 "$server" "$mountpoint" || fail "Unable to mount NFS share"

      echo "Target dir $target"
      mkdir -p "$target"

      echo "Dumping core file"
      makedumpfile -D -c -d 31 /proc/vmcore "$target/dumpfile"

      echo "Rebooting"
      #reboot -f
    '';
  };
}