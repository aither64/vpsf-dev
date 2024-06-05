{ config, pkgs, lib, ... }:
with lib;
let
  qemuCfg = config.boot.qemu;

  nfsCfg = config.services.nfs.server;

in {
  imports = [
    <vpsadmin/nixos/modules/vpsadminos-modules.nix>
    <vpsadminos/os/configs/qemu.nix>
    ../vpsadmin/settings.nix
  ];

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyWNChi95oRKXtSGdXtbthvXgWXk4y7uqpKVSIfqPq5GzI/S5WmAGe73Tc6o7aBzby09xpmLI/i41+jzQdSfxrGoCFRvpV+2W221jcdWyF/ojXiUciX2dQGS1gsKVcYNjLmqUrN/fNgY5XjuB10VU3nCenmRGGPep1Sx8CYi61lf5Qxb0AF71ylNJ8/rEXjkXad1vi7zTFteEWj3MmOoK1Fau4ykr6o4v2lSRWEvIxY9S+AFwNVqBtCC210ks1XYInaYuPnz0mdRmoOQIATLdBvIyHuWW5y8M9K+aplkLrUBI8abbrLcGze3lRusx4S3w2V4Pvgt9+DtpRM+kyC5gBhUxO8rY7+pBiIWP0WF87Xs5XfUe+nlhnbp23A/rAppvT6NnpvY10bvWTnKbnBlSyGWPUlYLVdqRwshLNSIKr2YByWorzNtnP63rTe5E8gHnpMs3+4f1Rdz0xgSx8kNZ0vAi7w2moFsjwQzc94Uzy52SkYkGgFYpkystXP05GKyB4N0nStoU25KmdX8dsSYGzF0WERy8KWx0tr1Hv/YONWek7IIHDZin5cTyhkbyktenlAyLJ5uj9Oty4MgKPsE3+GrMdczVTBf5ThhSuvyrZo2CqjTSBc6j7mEyEAAHqM6JNVyPRqhDYmtaK0iLTJCAyqnzQyLD9gxEBuTj/o+3rcw== aither@orion"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJlvsbOljzxEs7PHmiZHPo4Vcr9QfmWwlqvVZpGVAL6h aither@aitherdev"
    ];
  };

  services.openssh.settings.PermitRootLogin = "yes";

  system.secretsDir = "/secrets";
  vpsadmin.nodectld = {
    enable = true;
    settings = {
      vpsadmin = {
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

      console = {
        host = "0.0.0.0";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    htop
    tree
    git # for osctl hooks...
    iperf2
  ];

  tty.autologin.enable = true;
  services.haveged.enable = true;
  services.prometheus.exporters.node = {
    enable = true;
    extraFlags = [ "--collector.textfile.directory=/run/metrics" ];
  };
  services.prometheus.exporters.osctl.enable = true;
  boot.kernel.sysctl."sunrpc.nfs_debug" = 1023;

  osctld.settings.cpu_scheduler = {
    enable = true;
    packages."0".cpu_mask = "2-7";
  };
  osctl.exportfs.enable = true;

  networking.lxcbr.enable = true;
  networking.static.enable = mkDefault true;
  networking.hosts = {
    "172.16.106.41" = [ "os1" "os1.prg.vpsfree.cz" ];
    "172.16.106.42" = [ "os2" "os2.prg.vpsfree.cz" ];
  };

  environment.etc = {
    "resolv.conf".text = "nameserver 172.16.106.1";
    "ssh/ssh_host_rsa_key.pub".source = ../ssh_host_rsa_key.pub;
    "ssh/ssh_host_rsa_key" = { mode = "0600"; source = ../ssh_host_rsa_key; };
    "ssh/ssh_host_ed25519_key.pub".source = ../ssh_host_ed25519_key.pub;
    "ssh/ssh_host_ed25519_key" = { mode = "0600"; source = ../ssh_host_ed25519_key; };
    "gitconfig".text = ''
      [safe]
        directory = /mnt/vpsadminos
        directory = /mnt/vpsadminos-templates
        directory = /mnt/vpsadmin
        directory = /mnt/haveapi
    '';
  };

  services.nfs.server = {
    enable = true;
    mountdPort = 20048;
    statdPort = 662;
    lockdPort = 32769;
  };
  networking.firewall.extraCommands = ''
    # rpcbind
    iptables -A nixos-fw -p tcp --dport 111 -j nixos-fw-accept
    iptables -A nixos-fw -p udp --dport 111 -j nixos-fw-accept

    # nfsd
    iptables -A nixos-fw -p tcp --dport ${toString nfsCfg.nfsd.port} -j nixos-fw-accept
    iptables -A nixos-fw -p udp --dport ${toString nfsCfg.nfsd.port} -j nixos-fw-accept

    # mountd
    iptables -A nixos-fw -p tcp --dport ${toString nfsCfg.mountdPort} -j nixos-fw-accept
    iptables -A nixos-fw -p udp --dport ${toString nfsCfg.mountdPort} -j nixos-fw-accept

    # statd
    iptables -A nixos-fw -p tcp --dport ${toString nfsCfg.statdPort} -j nixos-fw-accept
    iptables -A nixos-fw -p udp --dport ${toString nfsCfg.statdPort} -j nixos-fw-accept

    # lockd
    iptables -A nixos-fw -p tcp --dport ${toString nfsCfg.lockdPort} -j nixos-fw-accept
    iptables -A nixos-fw -p udp --dport ${toString nfsCfg.lockdPort} -j nixos-fw-accept
  '';

  boot.qemu = {
    # cpus = 8;
    # cpu.cores = 8;

    cpus = 16;
    cpu.sockets = 2;
    cpu.cores = 8;

    memory = 10240;

    sharedFileSystems = [
      {
        handle = "hostNixPath";
        hostPath = "/home/aither/workspace/nixpkgs/vpsadminos";
        guestPath = "/mnt/nixpkgs";
      }
      {
        handle = "hostOs";
        hostPath = "/home/aither/workspace/vpsadmin/vpsadminos";
        guestPath = "/mnt/vpsadminos";
      }
      {
        handle = "hostVpsAdmin";
        hostPath = "/home/aither/workspace/vpsadmin/vpsadmin";
        guestPath = "/mnt/vpsadmin";
      }
      {
        handle = "hostHaveApi";
        hostPath = "/home/aither/workspace/haveapi/haveapi";
        guestPath = "/mnt/haveapi";
      }
      {
        handle = "hostLxc";
        hostPath = "/home/aither/workspace/lxc";
        guestPath = "/mnt/lxc";
      }
      {
        handle = "hostLxcfs";
        hostPath = "/home/aither/workspace/lxcfs";
        guestPath = "/mnt/lxcfs";
      }
      {
        handle = "hostHtop";
        hostPath = "/home/aither/workspace/htop";
        guestPath = "/mnt/htop";
      }
    ];

    network = {
      mode = "bridge";
      bridge.link = "br0";
    };
  };

  boot.zfs.pools = mkOverride 500 {
    tank = {
      layout = [
        { type = "raidz"; devices = [ "sda" ]; }
      ];
      install = true;
      share = "once";
    };
  };

  boot.postBootCommands = ''
    mount -a

    mkdir -p /mnt/vpsadmin-bind /mnt/haveapi-bind
    mount --bind /mnt/vpsadmin /mnt/vpsadmin-bind
    mount --bind /mnt/haveapi /mnt/haveapi-bind
  '';

  programs.bash.root.historyPools = mkDefault [ "tank" ];

  os.channel-registration.enable = mkDefault false;

  nix.nixPath = [
    "nixpkgs=/mnt/nixpkgs"
    "nixpkgs-overlays=/mnt/vpsadminos/os/overlays/common.nix"
  ];
}
