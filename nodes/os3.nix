{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;
in {
  imports = [
    ./base.nix
  ];

  networking.hostName = "os3.prg.vpsfree.cz";
  vpsadmin.nodectld.settings.vpsadmin.node_id = 52;

  boot.qemu.disks = [
    { device = "os3-tank.dat"; type = "file"; }
  ];

  networking.static = {
    ip = net.nodes.os3.string;
    interface = "eth0";
    route = net.nodes.os3.string;
    gateway = net.gateway;
  };
}
