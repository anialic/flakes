{ lib, ... }:
{
  modules.base = {
    options.fonts = {
      enable = lib.mkEnableOption "font configuration";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "roboto"
          "noto-fonts"
          "noto-fonts-cjk-sans"
          "noto-fonts-cjk-serif"
          "noto-fonts-color-emoji"
          "jetbrains-mono"
        ];
        description = "Font packages to install (as package attribute names)";
      };
      nerdFonts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "jetbrains-mono"
          "roboto-mono"
        ];
        description = "Nerd font variants to install";
      };
      defaultFonts = {
        serif = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "Noto Serif"
            "Noto Serif CJK SC"
          ];
        };
        sansSerif = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "Noto Sans"
            "Noto Sans CJK SC"
          ];
        };
        monospace = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "JetBrains Mono" ];
        };
        emoji = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "Noto Color Emoji" ];
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
      lib.mkIf node.base.fonts.enable {
        fonts = {
          enableDefaultPackages = false;
          packages =
            (map (p: pkgs.${p}) node.base.fonts.packages)
            ++ (map (f: pkgs.nerd-fonts.${f}) node.base.fonts.nerdFonts);
          fontconfig = {
            enable = true;
            defaultFonts = {
              inherit (node.base.fonts.defaultFonts)
                serif
                sansSerif
                monospace
                emoji
                ;
            };
          };
        };
      };
  };
}
