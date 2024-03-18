{ config, pkgs, lib, ... }:
{
  fileSystems."/mnt/vpsadmin-db" = {
    # device = "/dev/sdb1";
    device = "/dev/disk/by-uuid/d6ba04de-76dc-442a-8b86-6e48375bdbe1";
    fsType = "ext4";
  };

  boot.postBootCommands = ''
    mkdir -p /mnt/vpsadmin-db
    mount /mnt/vpsadmin-db
  '';

  osctl.pools.tank = {
    users.vpsadmin-db = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers.vpsadmin-db = {
      user = "vpsadmin-db";

      interfaces = [
        {
          name = "eth0";
          type = "bridge";
          link = "br0";
        }
      ];

      mounts = [
        {
          type = "bind";
          fs = "/mnt/vpsadmin-db";
          mountpoint = "/var/lib/mysql";
          opts = "bind,create=dir";
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
            { address = "192.168.122.10"; prefixLength = 24; }
          ];

          networking.defaultGateway = {
            address = "192.168.122.1";
            interface = "eth0";
          };

          networking.nameservers = [ "192.168.122.1" ];

          vpsadmin.database = {
            enable = true;
            defaultConfig = false;
            allowedIPv4Ranges = [
              "192.168.122.0/24"
            ];
          };
        };
    };
  };
}
