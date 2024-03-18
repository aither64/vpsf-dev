{ config, pkgs, lib, ... }:
{
  vpsadmin.cluster."vpsfree.cz" = {
    productionEnvironmentId = 1;

    plugins = [
      "monitoring"
      "newslog"
      "outage_reports"
      "payments"
      "requests"
      "webui"
    ];

    database = {
      machine = "cz.vpsfree/vpsadmin/database";
    };

    api = {
      database = {
        user = "vpsadmin";
        name = "vpsadmin";
        passwordFile = "/private/vpsadmin-db.pw";
      };

      domain = "api.vpsfree.cz";

      machines = {
        "cz.vpsfree/vpsadmin/api1" = { primary = true; };
        "cz.vpsfree/vpsadmin/api2" = {};
      };
    };

    console-router = {
      database = {
        user = "vpsadmin";
        name = "vpsadmin";
        passwordFile = "/private/vpsadmin-db.pw";
      };

      domain = "console1.vpsfree.cz";
    };

    webui = {
      domain = "vpsadmin.vpsfree.cz";

      privateConfigFile = "/private/vpsadmin-webui.php";

      machines = {
        "cz.vpsfree/vpsadmin/webui1" = {};
        "cz.vpsfree/vpsadmin/webui2" = {};
      };
    };

    redis = {
      passwordFile = "/private/vpsadmin-redis.pw";

      machines = {
        "cz.vpsfree/vpsadmin/redis" = {};
      };
    };

    download-mounter = {
      api.tokenFile = "/private/vpsadmin-api.token";

      domain = "download.vpsfree.cz";
    };

    frontend = {
      machines = {
        "cz.vpsfree/vpsadmin/front1" = {};
      };
    };
  };
}
