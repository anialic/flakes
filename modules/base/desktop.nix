{ lib, ... }:
{
  modules.base = {
    options.desktop = {
      enable = lib.mkEnableOption "desktop environment support";

      kmscon = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        font = lib.mkOption {
          type = lib.types.str;
          default = "JetBrainsMono Nerd Font";
        };
        fontPackage = lib.mkOption {
          type = lib.types.str;
          default = "nerd-fonts.jetbrains-mono";
        };
        fontSize = lib.mkOption {
          type = lib.types.int;
          default = 14;
        };
      };

      bluetooth.enable = lib.mkEnableOption "bluetooth";

      audio.enable = lib.mkEnableOption "PipeWire audio";

      power = {
        enable = lib.mkEnableOption "power management";
        handlePowerKey = lib.mkOption {
          type = lib.types.str;
          default = "suspend";
        };
        handleLidSwitch = lib.mkOption {
          type = lib.types.str;
          default = "suspend";
        };
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      let
        cfg = node.base.desktop;
        getFontPkg = path: lib.foldl' (acc: part: acc.${part}) pkgs (lib.splitString "." path);
      in
      lib.mkIf cfg.enable {
        services = {
          kmscon = lib.mkIf cfg.kmscon.enable {
            enable = true;
            fonts = [
              {
                name = cfg.kmscon.font;
                package = getFontPkg cfg.kmscon.fontPackage;
              }
            ];
            extraConfig = "font-size=${toString cfg.kmscon.fontSize}";
          };

          udisks2.enable = true;
          udev.packages = [ pkgs.usbutils ];

          pipewire = lib.mkIf cfg.audio.enable {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;
          };

          logind = lib.mkIf cfg.power.enable {
            lidSwitch = cfg.power.handleLidSwitch;
            extraConfig = ''
              HandlePowerKey=${cfg.power.handlePowerKey}
            '';
          };

          upower.enable = cfg.power.enable;
        };

        hardware.bluetooth = lib.mkIf cfg.bluetooth.enable {
          enable = true;
          powerOnBoot = true;
          settings.General.Experimental = true;
        };

        security.rtkit.enable = cfg.audio.enable;
      };
  };
}
