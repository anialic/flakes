{ lib, ... }:
{
  modules.gui = {
    options.waybar = {
      enable = lib.mkEnableOption "Waybar status bar";
      autostart = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      fontSize = lib.mkOption {
        type = lib.types.int;
        default = 11;
      };
      height = lib.mkOption {
        type = lib.types.int;
        default = 24;
      };
      margin = {
        top = lib.mkOption {
          type = lib.types.int;
          default = 6;
        };
        left = lib.mkOption {
          type = lib.types.int;
          default = 6;
        };
        right = lib.mkOption {
          type = lib.types.int;
          default = 6;
        };
        bottom = lib.mkOption {
          type = lib.types.int;
          default = 0;
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
      lib.mkIf (node.gui.enable && node.gui.waybar.enable) (
        let
          colors = {
            bg = "rgba(0, 0, 0, 0.55)";
            fg = "#e0e0e0";
            fg-dim = "#888888";
            hover = "rgba(54, 58, 79, 0.4)";
            critical = "rgba(255, 107, 107, 0.25)";
            workspace = "#C8CFE8";
          };

          waybarConfig = pkgs.writeText "config.jsonc" (
            lib.generators.toJSON { } {
              layer = "top";
              position = "top";
              margin-top = node.gui.waybar.margin.top;
              margin-left = node.gui.waybar.margin.left;
              margin-bottom = node.gui.waybar.margin.bottom;
              margin-right = node.gui.waybar.margin.right;
              inherit (node.gui.waybar) height;
              modules-left = [
                "niri/workspaces"
                "niri/window"
              ];
              modules-center = [ ];
              modules-right = [
                "tray"
                "network"
                "pulseaudio"
                "backlight"
                "battery"
                "clock"
              ];

              "niri/workspaces" = {
                format = "{icon}";
                format-icons = {
                  default = "○";
                  active = "●";
                };
              };
              "niri/window" = {
                format = "{title}";
                icon = true;
                icon-size = 15;
                max-length = 30;
              };
              tray.spacing = 10;
              network = {
                interval = 5;
                format-wifi = "󰤨 {essid}";
                format-ethernet = "󰈀 {ipaddr}";
                format-disconnected = "󰤭 Disconnected";
                tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}";
                tooltip-format-ethernet = "{ipaddr}/{cidr}";
              };
              pulseaudio = {
                format = "{icon} {volume}%";
                format-muted = "󰸈 {volume}%";
                format-icons = {
                  default = [
                    "󰕿"
                    "󰖀"
                    "󰕾"
                  ];
                  headphone = "󰋋";
                  headset = "󰋎";
                };
                on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.0";
                on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- -l 1.0";
              };
              backlight = {
                format = "{icon} {percent}%";
                format-icons = [
                  "󰃞"
                  "󰃟"
                  "󰃠"
                ];
                on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set +2%";
                on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 2%-";
                on-click = "${pkgs.brightnessctl}/bin/brightnessctl --device=kbd_backlight s 0";
                on-click-right = "${pkgs.brightnessctl}/bin/brightnessctl --device=kbd_backlight s 10";
              };
              battery = {
                interval = 10;
                states = {
                  warning = 30;
                  critical = 15;
                };
                format = "{icon} {capacity}%";
                format-charging = "󰂄 {capacity}%";
                format-plugged = "󰚥 {capacity}%";
                format-icons = [
                  "󰂎"
                  "󰁺"
                  "󰁻"
                  "󰁼"
                  "󰁽"
                  "󰁾"
                  "󰁿"
                  "󰂀"
                  "󰂁"
                  "󰂂"
                  "󰁹"
                ];
                tooltip-format = "{timeTo} • {power}W";
              };
              clock = {
                interval = 1;
                format = "󰥔 {:%H:%M}";
                format-alt = "󰃭 {:%Y-%m-%d}";
                tooltip-format = "<tt>{calendar}</tt>";
              };
            }
          );

          waybarStyle = pkgs.writeText "style.css" ''
            * {
              font-family: "RobotoMono Nerd Font", "Noto Sans CJK SC", sans-serif;
              font-size: ${toString node.gui.waybar.fontSize}px;
              font-weight: 500;
              min-height: 0;
            }
            window#waybar {
              background: transparent;
              color: ${colors.fg};
            }
            #workspaces {
              background-color: ${colors.bg};
              padding: 0 6px;
              border-radius: 10px;
            }
            #window {
              background-color: ${colors.bg};
              padding: 0 11px;
              border-radius: 10px;
              margin-left: 6px;
            }
            window#waybar.empty #window {
              background-color: transparent;
            }
            #workspaces button {
              color: ${colors.fg-dim};
              background: transparent;
              padding: 0 6px;
              border: none;
              transition: color 0.2s, background-color 0.2s;
            }
            #workspaces button.active {
              color: ${colors.workspace};
            }
            #workspaces button:hover {
              color: ${colors.fg};
            }
            #tray, #network, #pulseaudio, #backlight, #battery, #clock {
              background-color: ${colors.bg};
              padding: 0 11px;
              margin-left: 6px;
              border-radius: 10px;
              transition: background-color 0.2s;
            }
            #tray:hover, #network:hover, #pulseaudio:hover, #backlight:hover, #battery:hover, #clock:hover {
              background-color: ${colors.hover};
            }
            #tray { margin-left: 0; }
            #battery.critical {
              animation: blink-critical 1.2s ease-in-out infinite alternate;
            }
            #battery.warning:not(.charging) {
              color: #ffaa44;
            }
            @keyframes blink-critical {
              from { background-color: ${colors.bg}; }
              to { background-color: ${colors.critical}; }
            }
            tooltip {
              background-color: rgba(0, 0, 0, 0.92);
              border: 1px solid rgba(255, 255, 255, 0.12);
              border-radius: 8px;
              padding: 6px 10px;
            }
            tooltip label {
              color: ${colors.fg};
              font-size: ${toString (node.gui.waybar.fontSize + 1)}px;
            }
          '';
        in
        {
          environment.systemPackages = [ pkgs.waybar ];
          environment.etc."xdg/waybar/config.jsonc".source = waybarConfig;
          environment.etc."xdg/waybar/style.css".source = waybarStyle;

          systemd = lib.mkIf node.gui.waybar.autostart {
            packages = [ pkgs.waybar ];
            user.services.waybar.wantedBy = [ "graphical-session.target" ];
          };
        }
      );
  };
}
