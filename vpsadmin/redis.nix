{ config, pkgs, lib, ... }:
{
  osctl.pools.tank = {
    users.vpsadmin-redis = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers.vpsadmin-redis = {
      user = "vpsadmin-redis";

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
          ];

          networking.interfaces.eth0.ipv4.addresses = [
            { address = "192.168.122.6"; prefixLength = 24; }
          ];

          networking.defaultGateway = {
            address = "192.168.122.1";
            interface = "eth0";
          };

          networking.nameservers = [ "192.168.122.1" ];

          vpsadmin.redis = {
            enable = true;
            passwordFile = "/private/vpsadmin-redis.pw";
            allowedIPv4Ranges = [
              "192.168.122.9/32"
            ];
          };
        };
    };
  };
}
