{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;

  vhosts = [
    "api.aitherdev.int.vpsfree.cz"
    "api-tmp.aitherdev.int.vpsfree.cz"
    "auth.aitherdev.int.vpsfree.cz"
    "auth-tmp.aitherdev.int.vpsfree.cz"
    "console.aitherdev.int.vpsfree.cz"
    "console-tmp.aitherdev.int.vpsfree.cz"
    "download.aitherdev.int.vpsfree.cz"
    "webui.aitherdev.int.vpsfree.cz"
    "webui-tmp.aitherdev.int.vpsfree.cz"
  ];

  makeVhosts = lib.listToAttrs (map (vhost: lib.nameValuePair vhost {
    addSSL = true;
    sslCertificate = "/private/vpsadmin-cert.crt";
    sslCertificateKey = "/private/vpsadmin-cert.key";
  }) vhosts);
in {
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
            net.vpsadmin.frontend.nixosAddress
          ];

          networking.defaultGateway = {
            address = net.gateway;
            interface = "eth0";
          };

          networking.nameservers = net.nameservers;

          networking.firewall.extraCommands = lib.concatMapStringsSep "\n" (port: ''
            iptables -A nixos-fw -p tcp --dport ${toString port} -s 127.0.0.0/8 -j nixos-fw-accept
            iptables -A nixos-fw -p tcp --dport ${toString port} -s 172.16.106.40/32 -j nixos-fw-accept
            iptables -A nixos-fw -p tcp --dport ${toString port} -s 172.16.107.0/24 -j nixos-fw-accept
          '') [ 80 443 4567 ];

          systemd.tmpfiles.rules = [
            "d /run/varnish 0755 varnish varnish -"
          ];

          vpsadmin.download-mounter = {
            enable = true;
            api.url = "http://${net.aitherdev.address}:4567";
            api.tokenFile = "/private/vpsadmin-api.token";
            mountpoint = "/mnt/download";
          };

          vpsadmin.haproxy = {
            enable = true;

            api.prod = {
              frontend.bind = [ "unix@/run/haproxy/vpsadmin-api.sock mode 0666" ];
              backends = [
                {
                  host = net.vpsadmin.api.address;
                  port = 9292;
                }
              ];
            };

            console-router.prod = {
              frontend.bind = [ "unix@/run/haproxy/vpsadmin-console-router.sock mode 0666" ];
              # frontend.port = 5002;
              backends = [
                {
                  host = net.vpsadmin.api.address;
                  port = 8000;
                }
              ];
            };

            webui.prod = {
              frontend.bind = [ "unix@/run/haproxy/vpsadmin-webui.sock mode 0666" ];
              #frontend.port = 5001;
              backends = [
                {
                  host = net.vpsadmin.webui.address;
                  port = 80;
                }
              ];
            };
          };

          vpsadmin.varnish = {
            enable = true;

            bind = "/run/varnish/vpsadmin-varnish.sock,mode=0666";

            api.prod = {
              domain = "api.aitherdev.int.vpsfree.cz";
              backend.path = "/run/haproxy/vpsadmin-api.sock";
            };

            api.maintenance = {
              domain = "api-tmp.aitherdev.int.vpsfree.cz";
              backend.path = "/run/haproxy/vpsadmin-api.sock";
            };
          };

          vpsadmin.frontend = {
            enable = true;
            openFirewall = false;

            api = {
              production = {
                domain = "api.aitherdev.int.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5000;
                  # address = "unix:/run/haproxy/vpsadmin-api.sock";
                  address = "unix:/run/varnish/vpsadmin-varnish.sock";
                };
                maintenance.enable = false;
              };

              maintenance = {
                domain = "api-tmp.aitherdev.int.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5000;
                  # address = "unix:/run/haproxy/vpsadmin-api.sock";
                  address = "unix:/run/varnish/vpsadmin-varnish.sock";
                };
              };
            };

            auth = {
              production = {
                domain = "auth.aitherdev.int.vpsfree.cz";
                backend = {
                  address = "unix:/run/haproxy/vpsadmin-api.sock";
                };
                maintenance.enable = true;
              };

              maintenance = {
                domain = "auth-tmp.aitherdev.int.vpsfree.cz";
                backend = {
                  address = "unix:/run/haproxy/vpsadmin-api.sock";
                };
              };
            };

            console-router = {
              production = {
                domain = "console.aitherdev.int.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5002;
                  address = "unix:/run/haproxy/vpsadmin-console-router.sock";
                };
              };

              maintenance = {
                domain = "console-tmp.aitherdev.int.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5002;
                  address = "unix:/run/haproxy/vpsadmin-console-router.sock";
                };
              };
            };

            download-mounter = {
              production = {
                domain = "download.aitherdev.int.vpsfree.cz";
              };
            };

            webui = {
              production = {
                domain = "webui.aitherdev.int.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5001;
                  address = "unix:/run/haproxy/vpsadmin-webui.sock";
                };
                maintenance.enable = true;
              };

              maintenance = {
                domain = "webui-tmp.aitherdev.int.vpsfree.cz";
                backend = {
                  # host = "localhost";
                  # port = 5001;
                  address = "unix:/run/haproxy/vpsadmin-webui.sock";
                };
              };
            };
          };

          services.nginx.virtualHosts = makeVhosts;
        };
      };
  };
}
