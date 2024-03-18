{ config, ... }:
let
  net = import ../networking.nix;
in {
  vpsadmin = {
    plugins = [
      "monitoring"
      "newslog"
      "outage_reports"
      "payments"
      "requests"
      "webui"
    ];

    rabbitmq = {
      hosts = [
        net.vpsadmin.rabbitmq1.address
        net.vpsadmin.rabbitmq2.address
        net.vpsadmin.rabbitmq3.address
      ];
      virtualHost = "vpsadmin_dev";
    };
  };
}
