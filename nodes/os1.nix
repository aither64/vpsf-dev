{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;
in 
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
    { device = "os1-tank.dat"; type = "file"; size = "40G"; }
    { device = "vpsadmin-db.dat"; type = "file"; size = "60G"; }
  ];

  # networking.static = {
  #   ip = "172.16.106.41/24";
  #   interface = "eth0";
  #   route = "172.16.106.41/24";
  #   gateway = "172.16.106.1";
  # };

  networking.static = {
    enable = false;
    ip = net.nodes.os1.string;
  };

  networking.custom = ''
    ip link add name br0 type bridge
    ip link set br0 up

    ip link set eth0 up
    ip link set eth0 master br0

    ip addr add ${net.nodes.os1.string} dev br0
    ip route add default via ${net.gateway} dev br0
  '';

  services.bird2 = {
    enable = true;
    preStartCommands = ''
      touch /var/log/bird.log
      chown ${config.services.bird2.user}:${config.services.bird2.group} /var/log/bird.log
    '';
    config = ''
      router id ${net.nodes.os1.address};
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
