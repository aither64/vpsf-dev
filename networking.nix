let
  network = "172.16.106";

  prefix = 24;

  mkAddr = ip: rec {
    address = "${network}.${toString ip}";
    inherit prefix;
    string = "${network}.${toString ip}/${toString prefix}";
    nixosAddress = { inherit address; prefixLength = prefix; };
  };
in {
  inherit network prefix;

  networkRange = "${network}.0/${toString prefix}";

  nodes = {
    os1 = mkAddr 41;
    os2 = mkAddr 42;
    os3 = mkAddr 43;
    storage = mkAddr 45;
  };

  vpsadmin = {
    database = mkAddr 50;
    api = mkAddr 51;
    webui = mkAddr 52;
    frontend = mkAddr 53;
    mailer = mkAddr 54;
    redis = mkAddr 55;
    rabbitmq1 = mkAddr 60;
    rabbitmq2 = mkAddr 61;
    rabbitmq3 = mkAddr 62;
    dns1 = mkAddr 65;
    dns2 = mkAddr 66;
    dns3 = mkAddr 67;
  };

  gateway = "${network}.1";

  nameservers = [ "${network}.1" ];

  aitherdev = mkAddr 40;
}
