{ config, pkgs, lib, ... }:
{
  osctl.pools.tank = {
    users.vpsadmin-mailer = {
      uidMap = [ "0:500000:65536" ];
      gidMap = [ "0:500000:65536" ];
    };

    containers.vpsadmin-mailer = {
      user = "vpsadmin-mailer";

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
            { address = "192.168.122.11"; prefixLength = 24; }
          ];

          networking.defaultGateway = {
            address = "192.168.122.1";
            interface = "eth0";
          };

          networking.nameservers = [ "192.168.122.1" ];

          vpsadmin.nodectld = {
            enable = true;
            settings = {
              vpsadmin = {
                node_id = 100;
                node_name = "mail1.prg";
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
                username = "mail1.prg";
              };
              mailer = {
                smtp_server = "127.0.0.1";
                smtp_port = 25;
              };
            };
          };

          services.postfix.enable = true;
        };
    };
  };
}
