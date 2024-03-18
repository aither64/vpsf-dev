{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;
in {
  osctl.pools.tank = {
    users.vpsadmin-api = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers.vpsadmin-api = {
      user = "vpsadmin-api";

      interfaces = [
        {
          name = "eth0";
          type = "bridge";
          link = "br0";
        }
      ];

      autostart.enable = true;

      config =
        { config, pkgs, lib, ... }:
        {
          imports = [
            <vpsadmin/nixos/modules/nixos-modules.nix>
            ./settings.nix
          ];

          networking.interfaces.eth0.ipv4.addresses = [
            net.vpsadmin.api.nixosAddress
          ];

          networking.defaultGateway = {
            address = net.gateway;
            interface = "eth0";
          };

          networking.nameservers = net.nameservers;


          vpsadmin.api = {
            enable = true;
            configDirectory =
              builtins.filterSource
              (path: type: !(type == "directory" && baseNameOf path == ".git"))
              /home/aither/workspace/vpsfree.cz/vpsfree-cz-configuration/configs/vpsadmin/api;
            address = net.vpsadmin.api.address;
            servers = 2;
            allowedIPv4Ranges = [
              "${net.vpsadmin.frontend.address}/32"
            ];
            database = {
              host = net.vpsadmin.database.address;
              user = "vpsadmin";
              name = "vpsadmin";
              passwordFile = "/private/vpsadmin-db.pw";
            };
            scheduler.enable = true;

            rake.tasks.payments-process.timer.enable = lib.mkForce false;
            rake.tasks.requests-ipqs.timer.enable = lib.mkForce false;
          };

          vpsadmin.supervisor = {
            enable = false;
            servers = 2;
            database = {
              host = net.vpsadmin.database.address;
              user = "vpsadmin";
              name = "vpsadmin";
              passwordFile = "/private/vpsadmin-db.pw";
            };
            rabbitmq = {
              username = "supervisor";
              passwordFile = "/private/vpsadmin-rabbitmq.pw";
            };
          };

          vpsadmin.console-router = {
            enable = true;
            allowedIPv4Ranges = [
              "${net.vpsadmin.frontend.address}/32"
            ];
            rabbitmq = {
              username = "console-router";
              passwordFile = "/private/vpsadmin-console-rabbitmq.pw";
            };
          };
        };
    };
  };
}
