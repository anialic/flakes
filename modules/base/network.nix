{ lib, ... }:
{
  modules.base = {
    options.network = {
      wired = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        interface = lib.mkOption {
          type = lib.types.str;
          default = "eth0";
        };
      };
      wireless = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        interface = lib.mkOption {
          type = lib.types.str;
          default = "wlan0";
        };
      };
    };

    module =
      { node, lib, ... }:
      {
        networking = {
          useDHCP = false;
          dhcpcd.enable = false;
          resolvconf.enable = false;
          networkmanager.enable = false;
          wireless.iwd.enable = node.base.network.wireless.enable;
          nftables.enable = true;
          useNetworkd = true;
        };

        systemd = {
          enableEmergencyMode = false;
          network.enable = true;
          network.wait-online.enable = false;
          network.networks =
            lib.optionalAttrs node.base.network.wired.enable {
              "10-${node.base.network.wired.interface}" = {
                name = node.base.network.wired.interface;
                DHCP = "yes";
              };
            }
            // lib.optionalAttrs node.base.network.wireless.enable {
              "10-${node.base.network.wireless.interface}" = {
                name = node.base.network.wireless.interface;
                DHCP = "yes";
                dhcpV4Config.RouteMetric = 2048;
                dhcpV6Config.RouteMetric = 2048;
              };
            };
        };
      };
  };
}
