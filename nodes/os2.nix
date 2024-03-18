{ config, pkgs, lib, ... }:
{
  imports = [
    ./base.nix
    #../repository.nix
  ];

  networking.hostName = "os2.prg.vpsfree.cz";
  vpsadmin.nodectld.settings = {
    vpsadmin = {
      node_id = 51;
      # node_name = "os2.prg";
    };
    rabbitmq = {
      username = "os2.prg";
    };
  };

  boot.qemu.disks = [
    { device = "/dev/zvol/tank/encrypted/libvirt/vpsadminos-os2-tank"; type = "blockdev"; }
    { device = "/dev/zvol/tank/encrypted/libvirt/vpsadminos-os2-dozer"; type = "blockdev"; }
  ];

  networking.static = {
    ip = "192.168.122.32/24";
    interface = "eth0";
    route = "192.168.122.32/24";
    gateway = "192.168.122.1";
  };

  services.zfs.autoScrub = {
    enable = false;
    startIntervals = [ "0 4 */14 * *" ];
  };

  services.zfs.zed.zedlets = {
    all-ruby.script = ''
      #!${pkgs.ruby}/bin/ruby
      require 'pp'

      f = File.open('/tmp/zedlet-ruby.txt', 'a')
      f.puts "yep"
      f.puts(ARGV.inspect)
      PP.pp(ENV, f)
      f.puts
      f.puts
      f.close
    '';
  };

  boot.zfs.pools = {
    tank = {
      layout = [
        { type = "raidz"; devices = [ "sda" ]; }
      ];
      install = true;
      share = "once";
      scrub = {
        enable = true;
        startIntervals =  [ "9 20 * * *" ];
        pauseIntervals = [ "0 7 * * *" ];
        resumeIntervals = [ "0 23 * * *" ];
        startCommand = ''[ "$(LC_ALL=C date '+\%a')" = "Mon" ] && scrubctl start tank'';
      };
      datasets."testik" = {
        properties.refquota = lib.mkDefault "10G";
        properties.quota = 20*1024*1024*1024;
      };
    };

    dozer = {
      layout = [
        { type = "raidz"; devices = [ "sdb" ]; }
      ];
      install = true;
      share = "once";
    };
  };

  # networking.bird = {
  #   enable = true;
  #   routerId = "66";

  #   protocol.kernel = {
  #     scanTime = 2;
  #     learn = true;
  #     extraConfig = ''
  #       export all;
  #     '';
  #   };

  #   protocol.device.scanTime = 2;

  #   protocol.ospf = {
  #     ospf1 = {
  #       extraConfig = ''
  #         import all;
  #         export all;
  #       '';

  #       area."0.0.0.0" = {
  #         networks = [
  #           "172.19.0.0/23"
  #           "172.19.8.0/21"
  #           "37.205.11.0/24"
  #           "185.8.166.0/24"
  #         ];

  #         interface = {
  #           "bond200" = {};
  #           "veth*" = {};
  #         };
  #       };
  #     };
  #   };
  # };

  services.bird2 = {
    enable = true;
    preStartCommands = ''
      touch /var/log/bird.log
      chown ${config.services.bird2.user}:${config.services.bird2.group} /var/log/bird.log
    '';
    config = ''
      router id 192.168.122.32;
      log "/var/log/bird.log" all;
      debug protocols all;

      protocol kernel kernel4 {
        persist;
        learn;
        scan time 10;

        ipv4 {
          export all;
          import all;
        };
      }

      protocol device {
        scan time 10;
      }

      protocol direct {
        interface "*";
      }

      protocol bgp vps0 {
        local as 4200001001;
        neighbor 172.16.9.9 as 4200009001;
        multihop 2;
        ttl security on;

        ipv4 {
          export none;
          import all;
        };

        graceful restart;
      }

      protocol bgp vps2 {
        local as 4200001001;
        neighbor 172.16.9.10 as 4200009002;
        multihop 2;
        ttl security on;

        ipv4 {
          export none;
          import all;
        };

        graceful restart;
      }
    '';
  };

  runit.halt.hooks = {
    "my-hook".source = pkgs.writeScript "my-hook" ''
      #!${pkgs.bash}/bin/bash
      echo hi halt hook!
      echo hook=$HALT_HOOK
      echo action=$HALT_ACTION
      echo reason=$HALT_REASON
    '';
  };

  # security.apparmor.enable = true;
  # security.apparmor.enableOnBoot = false;
  boot.enableUnifiedCgroupHierarchy = true;
  #boot.kernelVersion = "6.1.21";

  # services.prometheus.exporters.osbench = {
  #   enable = true;
  # };

  # services.build-vpsadminos-container-image-repository.vpsadminos = {
  #   enable = true;
  #   osVm.memory = 4096;
  #   osVm.disks = [
  #     { type = "file"; device = "/tank/sda.img"; size = "5G"; }
  #   ];
  # };

  # services.prometheus.exporters.node = {
  #   enabledCollectors = [ "hwmon" "mdadm" ];
  #   disabledCollectors = [ "hwmon" ];
  # };

  services.prometheus.exporters.ipmi.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

#os.channel-registration.enable = true;

  # swapDevices = [
  #   { device = "/dev/disk/by-label/kokes"; }
  #   { label = "superswap"; }
  # ];
}
