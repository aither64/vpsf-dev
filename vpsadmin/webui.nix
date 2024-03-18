{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;
in {
  osctl.pools.tank = {
    users.vpsadmin-webui = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers.vpsadmin-webui = {
      user = "vpsadmin-webui";

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
          fs = "/mnt/haveapi-bind";
          mountpoint = "/opt/haveapi";
          opts = "bind,create=dir";
        }
        {
          type = "bind";
          fs = "/mnt/vpsadmin-bind";
          mountpoint = "/opt/vpsadmin";
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
            net.vpsadmin.webui.nixosAddress
          ];

          networking.defaultGateway = {
            address = net.gateway;
            interface = "eth0";
          };

          networking.nameservers = net.nameservers;

          networking.firewall.allowedTCPPorts = [ 80 ];

          fileSystems."/opt/vpsadmin/webui/vendor/haveapi/client" = {
            device = "/opt/haveapi/clients/php";
            fsType = "none";
            options = [ "bind" ];
          };

          vpsadmin.webui = {
            enable = true;
            sourceCodeDir = "/opt/vpsadmin/webui";
            productionEnvironmentId = 1;
            domain = net.vpsadmin.webui.address;
            errorReporting = "E_ALL";
            api.externalUrl = "http://${net.aitherdev.address}:4567";
            api.internalUrl = "http://${net.aitherdev.address}:4567";
            extraConfig = ''
              require "/private/vpsadmin-webui.php";
            '';
            allowedIPv4Ranges = [
              "${net.vpsadmin.frontend.address}/32"
            ];
          };

          services.phpfpm.pools.adminer = {
            user = "adminer";
            settings = {
              "listen.owner" = config.services.nginx.user;
              "pm" = "dynamic";
              "pm.max_children" = 32;
              "pm.max_requests" = 500;
              "pm.start_servers" = 2;
              "pm.min_spare_servers" = 2;
              "pm.max_spare_servers" = 5;
              "php_admin_value[error_log]" = "stderr";
              "php_admin_flag[log_errors]" = true;
              "catch_workers_output" = true;
            };
            phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
          };

          services.nginx.virtualHosts.${net.vpsadmin.webui.address}.locations."= /adminer/adminer.php" =
            let
              version = "4.8.1";

              script = pkgs.fetchurl {
                url = "https://github.com/vrana/adminer/releases/download/v${version}/adminer-${version}-en.php";
                sha256 = "sha256:0sqi537gcd957ycrp5h463dwlgvgw2zm2h2xb8miwmxv37k6phsf";
              };

              rootDir = pkgs.runCommand "adminer-root" {} ''
                mkdir -p $out/adminer
                ln -s ${script} $out/adminer.php
                ln -s ${script} $out/adminer/adminer.php
              '';
            in {
              root = rootDir;
              extraConfig = ''
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:${config.services.phpfpm.pools.adminer.socket};
                include ${pkgs.nginx}/conf/fastcgi_params;
                include ${pkgs.nginx}/conf/fastcgi.conf;
                fastcgi_index adminer.php;
              '';
            };

          users.users.adminer = {
            isSystemUser = true;
            createHome = true;
            group = "adminer";
          };
          users.groups.adminer = {};
        };
    };
  };
}
