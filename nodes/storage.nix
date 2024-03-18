{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;
in {
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
    { device = "storage-tank.dat"; type = "file"; }
  ];

  networking.static = {
    ip = net.nodes.storage.string;
    interface = "eth0";
    route = net.nodes.storage.string;
    gateway = net.gateway;
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
