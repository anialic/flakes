{ lib, resource, ... }:
{
  modules.gui = {
    options.niri = {
      enable = lib.mkEnableOption "Niri compositor";
      username = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      useNautilus = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      hotkey = {
        terminal = lib.mkOption {
          type = lib.types.str;
          default = "foot";
        };
        launcher = lib.mkOption {
          type = lib.types.str;
          default = "fuzzel";
        };
        lockscreen = lib.mkOption {
          type = lib.types.str;
          default = "gtklock";
        };
      };
      layout = {
        gaps = lib.mkOption {
          type = lib.types.int;
          default = 6;
        };
        cornerRadius = lib.mkOption {
          type = lib.types.int;
          default = 10;
        };
        focusRingColor = lib.mkOption {
          type = lib.types.str;
          default = "#404040";
        };
      };
      swaybg = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        wallpaper = lib.mkOption {
          type = lib.types.path;
          default = resource + "/bg.png";
        };
      };
      swayidle = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        timeout = lib.mkOption {
          type = lib.types.int;
          default = 900;
        };
      };
      gtklock = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        wallpaper = lib.mkOption {
          type = lib.types.path;
          default = resource + "/lock.png";
        };
        blurRadius = lib.mkOption {
          type = lib.types.str;
          default = "14x5";
        };
        clockFontSize = lib.mkOption {
          type = lib.types.int;
          default = 72;
        };
        inputFieldFontSize = lib.mkOption {
          type = lib.types.int;
          default = 14;
        };
        inputFieldWidth = lib.mkOption {
          type = lib.types.int;
          default = 280;
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
      lib.mkIf (node.gui.enable && node.gui.niri.enable) (
        let
          niriConfig = pkgs.writeText "config.kdl" ''
            hotkey-overlay {
                skip-at-startup
            }
            input {
                keyboard {
                    xkb {
                        options "caps:escape"
                    }
                }
                touchpad {
                    tap
                    natural-scroll
                }
            }
            gestures {
                hot-corners {
                    off
                }
            }
            layout {
                gaps ${toString node.gui.niri.layout.gaps}
                default-column-width {
                    proportion 0.5
                }
                focus-ring {
                    active-color "${node.gui.niri.layout.focusRingColor}"
                }
            }
            window-rule {
                geometry-corner-radius ${toString node.gui.niri.layout.cornerRadius}
                clip-to-geometry true
            }
            window-rule {
                match app-id="org.gnome.Nautilus"
                open-floating true
            }
            prefer-no-csd
            binds {
                Mod+Return {
                    spawn "${node.gui.niri.hotkey.terminal}";
                }
                Mod+D {
                    spawn "${node.gui.niri.hotkey.launcher}";
                }
                Mod+Alt+L {
                    spawn "${node.gui.niri.hotkey.lockscreen}";
                }
                Mod+Shift+V {
                    spawn-sh "cliphist list | fuzzel -d | cliphist decode | wl-copy";
                }
                Mod+Q {
                    close-window;
                }
                Mod+H {
                    focus-column-left;
                }
                Mod+L {
                    focus-column-right;
                }
                Mod+Ctrl+H {
                    move-column-left;
                }
                Mod+Ctrl+L {
                    move-column-right;
                }
                Mod+Tab { 
                    focus-workspace-previous;
                }
                Mod+J {
                    focus-workspace-down;
                }
                Mod+K {
                    focus-workspace-up;
                }
                Mod+Ctrl+J {
                    move-column-to-workspace-down;
                }
                Mod+Ctrl+K {
                    move-column-to-workspace-up;
                }
                Mod+1 { focus-workspace 1; }
                Mod+2 { focus-workspace 2; }
                Mod+3 { focus-workspace 3; }
                Mod+4 { focus-workspace 4; }
                Mod+5 { focus-workspace 5; }
                Mod+6 { focus-workspace 6; }
                Mod+7 { focus-workspace 7; }
                Mod+8 { focus-workspace 8; }
                Mod+9 { focus-workspace 9; }
                Mod+Ctrl+1 { move-column-to-workspace 1; }
                Mod+Ctrl+2 { move-column-to-workspace 2; }
                Mod+Ctrl+3 { move-column-to-workspace 3; }
                Mod+Ctrl+4 { move-column-to-workspace 4; }
                Mod+Ctrl+5 { move-column-to-workspace 5; }
                Mod+Ctrl+6 { move-column-to-workspace 6; }
                Mod+Ctrl+7 { move-column-to-workspace 7; }
                Mod+Ctrl+8 { move-column-to-workspace 8; }
                Mod+Ctrl+9 { move-column-to-workspace 9; }
                Mod+R { switch-preset-column-width; }
                Mod+F { maximize-column; }
                Mod+Shift+F { fullscreen-window; }
                Mod+C { center-column; }
                Mod+Minus { set-column-width "-10%"; }
                Mod+Equal { set-column-width "+10%"; }
                Mod+Shift+S { screenshot; }
                Mod+Shift+Ctrl+S { screenshot-screen; }
                XF86MonBrightnessUp allow-when-locked=true {
                    spawn "brightnessctl" "--class=backlight" "set" "+10%";
                }
                XF86MonBrightnessDown allow-when-locked=true {
                    spawn "brightnessctl" "--class=backlight" "set" "10%-";
                }
                XF86AudioRaiseVolume allow-when-locked=true {
                    spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
                }
                XF86AudioLowerVolume allow-when-locked=true {
                    spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                }
                XF86AudioMute allow-when-locked=true {
                    spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                }
                XF86AudioMicMute allow-when-locked=true {
                    spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                }
                XF86AudioPlay allow-when-locked=true { spawn-sh "playerctl play-pause"; }
                XF86AudioStop allow-when-locked=true { spawn-sh "playerctl stop"; }
                XF86AudioPrev allow-when-locked=true { spawn-sh "playerctl previous"; }
                XF86AudioNext allow-when-locked=true { spawn-sh "playerctl next"; }
            }
          '';

          bg-blurred = pkgs.runCommand "bg-blurred.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
            magick ${node.gui.niri.gtklock.wallpaper} -blur ${node.gui.niri.gtklock.blurRadius} $out
          '';
        in
        {
          programs.niri = {
            enable = true;
            useNautilus = node.gui.niri.useNautilus;
          };
          environment.systemPackages =
            with pkgs;
            [
              cliphist
              wl-clipboard-rs
              brightnessctl
              playerctl
              libnotify
            ]
            ++ lib.optional node.gui.niri.useNautilus nautilus
            ++ lib.optional node.gui.niri.swaybg.enable swaybg
            ++ lib.optional node.gui.niri.swayidle.enable swayidle;

          services = {
            gnome.gnome-keyring.enable = true;
            greetd = {
              enable = true;
              settings = rec {
                initial_session = {
                  command = "${lib.getExe' pkgs.niri "niri-session"}";
                  user = node.gui.niri.username;
                };
                default_session = initial_session;
              };
            };
          };

          systemd.services.greetd.serviceConfig = {
            Type = lib.mkForce "simple";
            ExecStartPre = [ "-${pkgs.coreutils}/bin/kill -SIGRTMIN+21 1" ];
            ExecStopPost = [ "-${pkgs.coreutils}/bin/kill -SIGRTMIN+20 1" ];
          };

          systemd.user.services.polkit-gnome-authentication-agent-1 = {
            description = "polkit-gnome-authentication-agent-1";
            wantedBy = [ "graphical-session.target" ];
            wants = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
              Restart = "on-failure";
              RestartSec = 1;
              TimeoutStopSec = 10;
            };
          };

          systemd.user.services.wl-paste = {
            enable = true;
            description = "Wayland clipboard manager";
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
              Restart = "on-failure";
              RestartSec = 3;
            };
          };

          systemd.user.services.swaybg = lib.mkIf node.gui.niri.swaybg.enable {
            enable = true;
            description = "Sway background daemon";
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${lib.getExe pkgs.swaybg} -i ${node.gui.niri.swaybg.wallpaper} -m fill";
              Restart = "on-failure";
              RestartSec = 3;
            };
          };

          systemd.user.services.swayidle = lib.mkIf node.gui.niri.swayidle.enable {
            enable = true;
            description = "Idle manager for Wayland";
            documentation = [ "man:swayidle(1)" ];
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart =
                "${pkgs.swayidle}/bin/swayidle -w "
                + "timeout ${toString node.gui.niri.swayidle.timeout} '${pkgs.systemd}/bin/systemctl suspend' "
                + "lock '${pkgs.gtklock}/bin/gtklock' "
                + "before-sleep '${pkgs.systemd}/bin/loginctl lock-session'";
              Restart = "on-failure";
              RestartSec = 3;
            };
          };

          programs.gtklock = lib.mkIf node.gui.niri.gtklock.enable {
            enable = true;
            config = {
              main = {
                gtk-theme = "adw-gtk3-dark";
                background = toString bg-blurred;
                time-format = "%H:%M";
                idle-hide = true;
                idle-timeout = 15;
                start-hidden = false;
              };
            };
            style = ''
              window {
                background-color: rgba(20, 25, 35, 0.6);
              }
              #clock-label {
                font-size: ${toString node.gui.niri.gtklock.clockFontSize}pt;
                color: rgba(255, 255, 255, 0.95);
                font-weight: 200;
              }
              #input-field {
                background-color: rgba(40, 45, 60, 0.5);
                border: 1px solid rgba(255, 255, 255, 0.15);
                border-radius: 12px;
                color: white;
                padding: 12px 18px;
                font-size: ${toString node.gui.niri.gtklock.inputFieldFontSize}pt;
                min-width: ${toString node.gui.niri.gtklock.inputFieldWidth}px;
              }
              #input-field:focus {
                border-color: rgba(255, 255, 255, 0.3);
                background-color: rgba(50, 55, 70, 0.6);
              }
              button {
                background-color: rgba(50, 55, 70, 0.4);
                border: 1px solid rgba(255, 255, 255, 0.12);
                border-radius: 8px;
                padding: 10px;
                color: rgba(255, 255, 255, 0.85);
              }
              button:hover {
                background-color: rgba(60, 65, 80, 0.6);
                border-color: rgba(255, 255, 255, 0.2);
              }
            '';
            modules = with pkgs; [
              gtklock-playerctl-module
              gtklock-powerbar-module
            ];
          };

          systemd.user.tmpfiles.users.${node.gui.niri.username}.rules = [
            "L+ %h/.config/niri/config.kdl 0644 ${node.gui.niri.username} users - ${niriConfig}"
          ];
        }
      );
  };
}
