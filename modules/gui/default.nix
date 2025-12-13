{ lib, ... }:
{
  modules.gui = {
    target = "nixos";

    options = {
      gtk = {
        theme = {
          package = lib.mkOption {
            type = lib.types.str;
            default = "adw-gtk3";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "adw-gtk3-dark";
          };
        };
        icon = {
          package = lib.mkOption {
            type = lib.types.str;
            default = "adwaita-icon-theme";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "Adwaita";
          };
        };
        cursor = {
          package = lib.mkOption {
            type = lib.types.str;
            default = "bibata-cursors";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "Bibata-Modern-Ice";
          };
          size = lib.mkOption {
            type = lib.types.int;
            default = 24;
          };
        };
        font = lib.mkOption {
          type = lib.types.str;
          default = "Roboto 11";
        };
      };
      gvfs.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      tumbler.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
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
      lib.mkIf node.gui.enable (
        let
          cfg = node.gui;

          gtkSettings = ''
            [Settings]
            gtk-theme-name=${cfg.gtk.theme.name}
            gtk-icon-theme-name=${cfg.gtk.icon.name}
            gtk-font-name=${cfg.gtk.font}
            gtk-cursor-theme-name=${cfg.gtk.cursor.name}
            gtk-cursor-theme-size=${toString cfg.gtk.cursor.size}
            gtk-application-prefer-dark-theme=1
          '';

          gtk2rc = ''
            gtk-theme-name="${cfg.gtk.theme.name}"
            gtk-icon-theme-name="${cfg.gtk.icon.name}"
            gtk-font-name="${cfg.gtk.font}"
            gtk-cursor-theme-name="${cfg.gtk.cursor.name}"
            gtk-cursor-theme-size=${toString cfg.gtk.cursor.size}
          '';

          cursorIndex = pkgs.writeTextFile {
            name = "cursor-index-theme";
            destination = "/share/icons/default/index.theme";
            text = ''
              [Icon Theme]
              Name=Default
              Comment=Default Cursor Theme
              Inherits=${cfg.gtk.cursor.name}
            '';
          };
        in
        {
          environment.systemPackages = [
            pkgs.${cfg.gtk.theme.package}
            pkgs.${cfg.gtk.icon.package}
            pkgs.${cfg.gtk.cursor.package}
            pkgs.gnome-themes-extra
            cursorIndex
          ]
          ++ map (p: pkgs.${p}) cfg.extraPackages;

          environment.etc = {
            "xdg/gtk-2.0/gtkrc".text = gtk2rc;
            "xdg/gtk-3.0/settings.ini".text = gtkSettings;
            "xdg/gtk-4.0/settings.ini".text = gtkSettings;
          };

          qt = {
            enable = true;
            style = "adwaita";
            platformTheme = "gnome";
          };

          programs.dconf = {
            enable = true;
            profiles.user.databases = [
              {
                settings."org/gnome/desktop/interface" = {
                  cursor-theme = cfg.gtk.cursor.name;
                  cursor-size = lib.gvariant.mkInt32 cfg.gtk.cursor.size;
                  color-scheme = "prefer-dark";
                  font-name = cfg.gtk.font;
                  document-font-name = cfg.gtk.font;
                  monospace-font-name = "Monospace 10";
                };
              }
            ];
          };

          services = {
            gvfs.enable = cfg.gvfs.enable;
            tumbler.enable = cfg.tumbler.enable;
          };
        }
      );
  };
}
