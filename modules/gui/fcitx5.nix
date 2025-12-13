{ lib, ... }:
{
  modules.gui = {
    target = "nixos";

    options.fcitx5 = {
      enable = lib.mkEnableOption "Fcitx5 input method";
      theme = lib.mkOption {
        type = lib.types.str;
        default = "FluentDark-solid";
      };
      hotkeys = {
        trigger = lib.mkOption {
          type = lib.types.str;
          default = "Control+space";
        };
        activate = lib.mkOption {
          type = lib.types.str;
          default = "VoidSymbol";
        };
        deactivate = lib.mkOption {
          type = lib.types.str;
          default = "VoidSymbol";
        };
        altTrigger = lib.mkOption {
          type = lib.types.str;
          default = "Shift_L";
        };
      };
      behavior = {
        allowInputMethodForPassword = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        showPreeditForPassword = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
      addons = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      lib.mkIf (node.gui.enable && node.gui.fcitx5.enable) {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5 = {
            addons =
              with pkgs;
              [
                fcitx5-fluent
                fcitx5-gtk
                kdePackages.fcitx5-chinese-addons
                fcitx5-pinyin-zhwiki
              ]
              ++ node.gui.fcitx5.addons;
            settings = {
              addons = {
                classicui.globalSection.Theme = node.gui.fcitx5.theme;
                pinyin.globalSection.FirstRun = "False";
              };
              inputMethod = {
                "Groups/0" = {
                  Name = "Default";
                  "Default Layout" = "us";
                  DefaultIM = "keyboard-us";
                };
                "Groups/0/Items/0" = {
                  Name = "keyboard-us";
                  Layout = "";
                };
                "Groups/0/Items/1" = {
                  Name = "pinyin";
                  Layout = "";
                };
              };
              globalOptions = {
                "Hotkey/TriggerKeys"."0" = node.gui.fcitx5.hotkeys.trigger;
                "Hotkey/ActivateKeys"."0" = node.gui.fcitx5.hotkeys.activate;
                "Hotkey/DeactivateKeys"."0" = node.gui.fcitx5.hotkeys.deactivate;
                "Hotkey/AltTriggerKeys"."0" = node.gui.fcitx5.hotkeys.altTrigger;
                "Hotkey/EnumerateGroupForwardKeys"."0" = "VoidSymbol";
                "Hotkey/EnumerateGroupBackwardKeys"."0" = "VoidSymbol";
                Behavior = {
                  AllowInputMethodForPassword = node.gui.fcitx5.behavior.allowInputMethodForPassword;
                  ShowPreeditForPassword = node.gui.fcitx5.behavior.showPreeditForPassword;
                };
              };
            };
            waylandFrontend = true;
            ignoreUserConfig = true;
          };
        };
      };
  };
}
