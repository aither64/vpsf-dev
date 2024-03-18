{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;
in {
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
            net.vpsadmin.redis.nixosAddress
          ];

          networking.defaultGateway = {
            address = net.gateway;
            interface = "eth0";
          };

          networking.nameservers = net.nameservers;

          vpsadmin.redis = {
            enable = true;
            passwordFile = "/private/vpsadmin-redis.pw";
            allowedIPv4Ranges = [
              "${net.vpsadmin.webui.address}/32"
            ];
          };
        };
    };
  };
}
