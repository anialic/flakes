{ lib, inputs, ... }:
{
  modules.apple = {
    target = "nixos";

    options = {
      peripheralFirmwareDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to firmware directory (default: auto-detect /boot/asahi)";
      };
      setupAsahiSound = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      batteryChargeLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 80;
      };
    };

    module =
      {
        node,
        lib,
        ...
      }:
      {
        imports = [ inputs.apple-silicon-support.nixosModules.apple-silicon-support ];

        hardware.asahi = {
          setupAsahiSound = node.apple.setupAsahiSound;
        }
        // lib.optionalAttrs (node.apple.peripheralFirmwareDirectory != null) {
          peripheralFirmwareDirectory = node.apple.peripheralFirmwareDirectory;
        };

        boot = {
          kernelParams = [ "apple_dcp.show_notch=1" ];
        };

        services.udev.extraRules = lib.mkIf (node.apple.batteryChargeLimit != null) ''
          SUBSYSTEM=="power_supply", KERNEL=="macsmc-battery", ATTR{charge_control_end_threshold}="${toString node.apple.batteryChargeLimit}"
        '';
      };
  };
}
