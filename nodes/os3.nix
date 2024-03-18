{ config, pkgs, lib, ... }:
{
  imports = [
    ./base.nix
  ];

  networking.hostName = "os3.prg.vpsfree.cz";
  vpsadmin.nodectld.settings.vpsadmin.node_id = 52;

  boot.qemu.disks = [
    { device = "/dev/zvol/tank/encrypted/libvirt/vpsadminos-os3-tank"; type = "blockdev"; }
  ];

  networking.static = {
    ip = "192.168.122.33/24";
    interface = "eth0";
    route = "192.168.122.33/24";
    gateway = "192.168.122.1";
  };
}
