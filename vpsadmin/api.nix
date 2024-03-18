{ config, pkgs, lib, ... }:
{
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
            { address = "192.168.122.8"; prefixLength = 24; }
          ];

          networking.defaultGateway = {
            address = "192.168.122.1";
            interface = "eth0";
          };

          networking.nameservers = [ "192.168.122.1" ];


          vpsadmin.api = {
            enable = true;
            configDirectory =
              builtins.filterSource
              (path: type: !(type == "directory" && baseNameOf path == ".git"))
              /home/aither/workspace/vpsfree.cz/vpsfree-cz-configuration/configs/vpsadmin/api;
            address = "192.168.122.8";
            servers = 2;
            allowedIPv4Ranges = [
              "192.168.122.7/32"
            ];
            database = {
              host = "192.168.122.10";
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
              host = "192.168.122.10";
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
              "192.168.122.7/32"
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
