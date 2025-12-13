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
      m1n1CustomLogo = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Custom boot logo (256x256 PNG)";
      };
      m1n1ExtraOptions = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Extra m1n1 options (e.g. for Mac mini display issues)";
      };
      showNotch = lib.mkOption {
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
      lib.mkIf node.apple.enable {
        imports = [ inputs.nixos-apple-silicon.nixosModules.apple-silicon-support ];

        hardware.asahi = {
          setupAsahiSound = node.apple.setupAsahiSound;
        }
        // lib.optionalAttrs (node.apple.peripheralFirmwareDirectory != null) {
          peripheralFirmwareDirectory = node.apple.peripheralFirmwareDirectory;
        };

        boot = {
          m1n1CustomLogo = node.apple.m1n1CustomLogo;
          m1n1ExtraOptions = node.apple.m1n1ExtraOptions;
          kernelParams = lib.optionals node.apple.showNotch [ "apple_dcp.show_notch=1" ];
        };

        services.udev.extraRules = lib.mkIf (node.apple.batteryChargeLimit != null) ''
          SUBSYSTEM=="power_supply", KERNEL=="macsmc-battery", ATTR{charge_control_end_threshold}="${toString node.apple.batteryChargeLimit}"
        '';
      };
  };
}
