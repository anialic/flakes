{ lib, ... }:
{
  modules.gui = {
    options.mako = {
      enable = lib.mkEnableOption "Mako notification daemon";
      autostart = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      backgroundColor = lib.mkOption {
        type = lib.types.str;
        default = "#2e34407f";
      };
      width = lib.mkOption {
        type = lib.types.int;
        default = 420;
      };
      height = lib.mkOption {
        type = lib.types.int;
        default = 120;
      };
      borderSize = lib.mkOption {
        type = lib.types.int;
        default = 3;
      };
      borderRadius = lib.mkOption {
        type = lib.types.int;
        default = 12;
      };
      maxIconSize = lib.mkOption {
        type = lib.types.int;
        default = 64;
      };
      defaultTimeout = lib.mkOption {
        type = lib.types.int;
        default = 5000;
      };
      margin = lib.mkOption {
        type = lib.types.int;
        default = 12;
      };
      padding = lib.mkOption {
        type = lib.types.str;
        default = "12,20";
      };
      urgency = {
        low = lib.mkOption {
          type = lib.types.str;
          default = "#cccccc";
        };
        normal = lib.mkOption {
          type = lib.types.str;
          default = "#99c0d0";
        };
        critical = lib.mkOption {
          type = lib.types.str;
          default = "#bf616a";
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
      lib.mkIf (node.gui.enable && node.gui.mako.enable) (
        let
          makoConfig = pkgs.writeText "config" ''
            sort=-time
            layer=overlay
            background-color=${node.gui.mako.backgroundColor}
            width=${toString node.gui.mako.width}
            height=${toString node.gui.mako.height}
            border-size=${toString node.gui.mako.borderSize}
            border-color=${node.gui.mako.urgency.normal}
            border-radius=${toString node.gui.mako.borderRadius}
            max-icon-size=${toString node.gui.mako.maxIconSize}
            default-timeout=${toString node.gui.mako.defaultTimeout}
            ignore-timeout=0
            margin=${toString node.gui.mako.margin}
            padding=${node.gui.mako.padding}

            [urgency=low]
            border-color=${node.gui.mako.urgency.low}

            [urgency=normal]
            border-color=${node.gui.mako.urgency.normal}

            [urgency=critical]
            border-color=${node.gui.mako.urgency.critical}
            default-timeout=0
          '';
        in
        {
          environment.systemPackages = [ pkgs.mako ];
          environment.etc."xdg/mako/config".source = makoConfig;

          systemd.user.services.mako = lib.mkIf node.gui.mako.autostart {
            enable = true;
            description = "Mako notification daemon";
            documentation = [ "man:mako(5)" ];
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "dbus";
              BusName = "org.freegui.Notifications";
              ExecStart = "${pkgs.mako}/bin/mako";
              ExecReload = "${pkgs.mako}/bin/makoctl reload";
              Restart = "on-failure";
              RestartSec = 3;
            };
          };
        }
      );
  };
}
