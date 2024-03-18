{ config, pkgs, lib, ... }:
{
  imports = [
    ./base.nix
  ];

  networking.hostName = "storage.prg.vpsfree.cz";
  vpsadmin.nodectld.settings = {
    vpsadmin = {
      node_id = 10;
      node_name = "storage.prg";
    };
    rabbitmq = {
      username = "storage.prg";
    };
  };

  boot.qemu.disks = [
    { device = "/dev/zvol/tank/encrypted/libvirt/vpsadminos-storage"; type = "blockdev"; }
  ];

  networking.static = {
    ip = "192.168.122.20/24";
    interface = "eth0";
    route = "192.168.122.20/24";
    gateway = "192.168.122.1";
  };

  boot.zfs.pools = lib.mkForce {
    storage = {
      layout = [
        { type = "raidz"; devices = [ "sda" ]; }
      ];
    };
  };

  programs.bash.root.historyPools = [ "storage" ];
}
