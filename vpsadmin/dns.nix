{ config, pkgs, lib, ... }:
let
  net = import ../networking.nix;

  instances = [
    { name = "vpsadmin-dns1"; ip = net.vpsadmin.dns1; nodeId = 200; nodeName = "dns1.prg"; }
    { name = "vpsadmin-dns2"; ip = net.vpsadmin.dns2; nodeId = 201; nodeName = "dns2.prg"; }
    { name = "vpsadmin-dns3"; ip = net.vpsadmin.dns3; nodeId = 202; nodeName = "dns3.prg"; }
  ];

  mkInstances = lib.listToAttrs (map (instance:
      lib.nameValuePair instance.name (mkInstance instance)
    ) instances);

  mkInstance = { name, ip, nodeId, nodeName }:
    {
      user = "vpsadmin-dns";

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
            ip.nixosAddress
          ];

          networking.defaultGateway = {
            address = net.gateway;
            interface = "eth0";
          };

          networking.nameservers = lib.mkForce net.nameservers;

          environment.systemPackages = with pkgs; [
            config.services.bind.package
            dnsutils
          ];

          services.bind = {
            enable = true;
            forwarders = lib.mkForce [];
            zones = [];
            directory = "/var/named";
            extraOptions = ''
              recursion no;
              allow-query-cache { none; };
            '';
            extraConfig = ''
              statistics-channels {
                inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
              };

              include "/var/named/vpsadmin/named.conf";
            '';
          };

          systemd.tmpfiles.rules = [
            "d '/var/named' 0750 named named - -"
          ];

          networking.firewall.allowedTCPPorts = [ 53 ];
          networking.firewall.allowedUDPPorts = [ 53 ];

          vpsadmin.nodectld = {
            enable = true;
            settings = {
              vpsadmin = {
                node_id = nodeId;
                node_name = nodeName;
                net_interfaces = [ "eth0" ];
                transaction_public_key = pkgs.writeText "transaction.key" ''
                  -----BEGIN PUBLIC KEY-----
                  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1Iu4qQ2vyoWVyZfIOQUj
                  mapvsBN1zPxM3Ewgez0VJ7seB6/lOH3FjJrYA1kKuuzp1qNcPpRu6NU3VxSGCuzB
                  qoK7J7Pxzj67sPguIrjA0lm3RJcu4G2qIneqbESBT6+cSG5E5QJpa8BWVpWfxK35
                  qg6KXlpL3wF4eBXm2B5aRMJkUAXLq4Hfxcdgkbux+oHayd81BiUOskeVq5vvCGe6
                  Ui28VrB4sgDNdMEGQDzIL2V+hjRECRXh1VfFa012z+yHiX1Ys1sbs+9OFHcoDQYJ
                  AjChL3bcijCU7BvxmeJhLJe7Q41maFYRrKsfgVgxO78oLMbRAolia8ZAtw8iZXBo
                  bQIDAQAB
                  -----END PUBLIC KEY-----
                '';
              };
              rabbitmq = {
                username = nodeName;
              };
              dns_server = {
                # config_root = "/var/named/vpsadmin/named.conf";
                # zone_template = "/var/named/vpsadmin/zone.%{name}";
              };
            };
          };
        };
    };
in {
  osctl.pools.tank = {
    users.vpsadmin-dns = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers = mkInstances;
  };
}
