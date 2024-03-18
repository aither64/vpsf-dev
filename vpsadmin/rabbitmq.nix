{ config, pkgs, lib, ... }:
let
  instances = [
    { name = "vpsadmin-rabbitmq1"; ip = "192.168.122.12"; }
    { name = "vpsadmin-rabbitmq2"; ip = "192.168.122.13"; }
    { name = "vpsadmin-rabbitmq3"; ip = "192.168.122.14"; }
  ];

  mkInstances = lib.listToAttrs (map (instance:
      lib.nameValuePair instance.name (mkInstance instance)
    ) instances);

  mkInstance = { name, ip }:
    {
      user = "vpsadmin-rabbitmq";

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
            { address = ip; prefixLength = 24; }
          ];

          networking.defaultGateway = {
            address = "192.168.122.1";
            interface = "eth0";
          };

          networking.nameservers = [ "192.168.122.1" ];

          networking.hosts = lib.listToAttrs (map (instance:
            lib.nameValuePair instance.ip [ instance.name ]
          ) instances);

          vpsadmin.rabbitmq = {
            enable = true;
            allowedIPv4Ranges = {
              cluster = [
                "192.168.122.12/24"
                "192.168.122.13/24"
                "192.168.122.14/24"
              ];
              clients = [
                "192.168.122.0/24"
              ];
              management = [
                "192.168.122.0/24"
              ];
            };
          };

          users.users.root = {
            openssh.authorizedKeys.keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyWNChi95oRKXtSGdXtbthvXgWXk4y7uqpKVSIfqPq5GzI/S5WmAGe73Tc6o7aBzby09xpmLI/i41+jzQdSfxrGoCFRvpV+2W221jcdWyF/ojXiUciX2dQGS1gsKVcYNjLmqUrN/fNgY5XjuB10VU3nCenmRGGPep1Sx8CYi61lf5Qxb0AF71ylNJ8/rEXjkXad1vi7zTFteEWj3MmOoK1Fau4ykr6o4v2lSRWEvIxY9S+AFwNVqBtCC210ks1XYInaYuPnz0mdRmoOQIATLdBvIyHuWW5y8M9K+aplkLrUBI8abbrLcGze3lRusx4S3w2V4Pvgt9+DtpRM+kyC5gBhUxO8rY7+pBiIWP0WF87Xs5XfUe+nlhnbp23A/rAppvT6NnpvY10bvWTnKbnBlSyGWPUlYLVdqRwshLNSIKr2YByWorzNtnP63rTe5E8gHnpMs3+4f1Rdz0xgSx8kNZ0vAi7w2moFsjwQzc94Uzy52SkYkGgFYpkystXP05GKyB4N0nStoU25KmdX8dsSYGzF0WERy8KWx0tr1Hv/YONWek7IIHDZin5cTyhkbyktenlAyLJ5uj9Oty4MgKPsE3+GrMdczVTBf5ThhSuvyrZo2CqjTSBc6j7mEyEAAHqM6JNVyPRqhDYmtaK0iLTJCAyqnzQyLD9gxEBuTj/o+3rcw== aither@orion"
            ];
          };

          services.openssh.settings.PermitRootLogin = "yes";
        };
    };
in {
  osctl.pools.tank = {
    users.vpsadmin-rabbitmq = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers = mkInstances;
  };
}
