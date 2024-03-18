{ config, pkgs, lib, ... }:
{
  osctl.pools.tank = {
    users.vpsadmin-front = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers.vpsadmin-front = {
      user = "vpsadmin-front";

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
            { address = "192.168.122.7"; prefixLength = 24; }
          ];

          networking.defaultGateway = {
            address = "192.168.122.1";
            interface = "eth0";
          };

          networking.nameservers = [ "192.168.122.1" ];

          vpsadmin.download-mounter = {
            enable = true;
            api.url = "http://192.168.122.1:4567";
            api.tokenFile = "/private/vpsadmin-api.token";
            mountpoint = "/mnt/download";
          };

          vpsadmin.haproxy = {
            enable = true;

            api.prod = {
              frontend.bind = [ "unix@/run/haproxy/vpsadmin-api.sock mode 0666" ];
              backends = builtins.genList (i: {
                host = "192.168.122.8";
                port = 9292 + i;
              }) 2;
            };

            console-router.prod = {
              frontend.bind = [ "unix@/run/haproxy/vpsadmin-console-router.sock mode 0666" ];
              # frontend.port = 5002;
              backends = [
                {
                  host = "192.168.122.8";
                  port = 8000;
                }
              ];
            };

            webui.prod = {
              frontend.bind = [ "unix@/run/haproxy/vpsadmin-webui.sock mode 0666" ];
              #frontend.port = 5001;
              backends = [
                {
                  host = "192.168.122.9";
                  port = 80;
                }
              ];
            };
          };

          vpsadmin.frontend = {
            enable = true;

            api = {
              production = {
                domain = "api.dev.home.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5000;
                  address = "unix:/run/haproxy/vpsadmin-api.sock";
                };
                maintenance.enable = true;
              };

              maintenance = {
                domain = "api-tmp.dev.home.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5000;
                  address = "unix:/run/haproxy/vpsadmin-api.sock";
                };
              };
            };

            auth = {
              production = {
                domain = "auth.dev.home.vpsfree.cz";
                backend = {
                  address = "unix:/run/haproxy/vpsadmin-api.sock";
                };
                maintenance.enable = true;
              };

              maintenance = {
                domain = "auth-tmp.dev.home.vpsfree.cz";
                backend = {
                  address = "unix:/run/haproxy/vpsadmin-api.sock";
                };
              };
            };

            console-router = {
              production = {
                domain = "console.dev.home.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5002;
                  address = "unix:/run/haproxy/vpsadmin-console-router.sock";
                };
              };

              maintenance = {
                domain = "console-tmp.dev.home.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5002;
                  address = "unix:/run/haproxy/vpsadmin-console-router.sock";
                };
              };
            };

            download-mounter = {
              production = {
                domain = "download.dev.home.vpsfree.cz";
              };
            };

            webui = {
              production = {
                domain = "webui.dev.home.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5001;
                  address = "unix:/run/haproxy/vpsadmin-webui.sock";
                };
                maintenance.enable = true;
              };

              maintenance = {
                domain = "webui-tmp.dev.home.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5001;
                  address = "unix:/run/haproxy/vpsadmin-webui.sock";
                };
              };
            };
          };
        };
      };
  };
}
