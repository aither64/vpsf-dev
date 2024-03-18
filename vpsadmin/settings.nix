{ config, ... }:
{
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
        "192.168.122.12"
        "192.168.122.13"
        "192.168.122.14"
      ];
      virtualHost = "vpsadmin_dev";
    };
  };
}
