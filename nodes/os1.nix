{ config, pkgs, lib, ... }:
{
  imports = [
    ./base.nix
    ../vpsadmin
  ];

  networking.hostName = "os1.prg.vpsfree.cz";
  vpsadmin.nodectld.settings = {
    vpsadmin = {
      node_id = 50;
      node_name = "os1.prg";
    };
    rabbitmq = {
      username = "os1.prg";
    };
  };

  boot.qemu.disks = [
    { device = "/dev/zvol/tank/encrypted/libvirt/vpsadminos-os1-tank"; type = "blockdev"; }
    { device = "/dev/zvol/tank/encrypted/libvirt/vpsadmin-db"; type = "blockdev"; }
  ];

  # networking.static = {
  #   ip = "192.168.122.31/24";
  #   interface = "eth0";
  #   route = "192.168.122.31/24";
  #   gateway = "192.168.122.1";
  # };

  networking.static = {
    enable = false;
    ip = "192.168.122.31/24";
  };

  networking.custom = ''
    ip link add name br0 type bridge
    ip link set br0 up

    ip link set eth0 up
    ip link set eth0 master br0

    ip addr add 192.168.122.31/24 dev br0
    ip route add default via 192.168.122.1 dev br0
  '';

  services.bird2 = {
    enable = true;
    preStartCommands = ''
      touch /var/log/bird.log
      chown ${config.services.bird2.user}:${config.services.bird2.group} /var/log/bird.log
    '';
    config = ''
      router id 192.168.122.31;
      log "/var/log/bird.log" all;
      debug protocols all;

      protocol kernel kernel4 {
        persist;
        learn;
        scan time 10;

        ipv4 {
          export all;
          import all;
        };
      }

      protocol device {
        scan time 10;
      }

      protocol direct {
        interface "*";
      }
    '';
  };
}
