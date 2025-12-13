{ lib, ... }:
{
  modules.gui = {
    options.fuzzel = {
      enable = lib.mkEnableOption "Fuzzel launcher";
      fontSize = lib.mkOption {
        type = lib.types.int;
        default = 12;
      };
      width = lib.mkOption {
        type = lib.types.int;
        default = 40;
      };
      borderRadius = lib.mkOption {
        type = lib.types.int;
        default = 10;
      };
      padding = lib.mkOption {
        type = lib.types.int;
        default = 12;
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      lib.mkIf (node.gui.enable && node.gui.fuzzel.enable) (
        let
          fuzzelConfig = pkgs.writeText "fuzzel.ini" ''
            [main]
            font=Roboto:size=${toString node.gui.fuzzel.fontSize}
            width=${toString node.gui.fuzzel.width}
            lines=15
            horizontal-pad=${toString node.gui.fuzzel.padding}
            vertical-pad=${toString node.gui.fuzzel.padding}
            inner-pad=8
            image-size-ratio=0.5
            layer=overlay
            exit-on-keyboard-focus-loss=yes

            [colors]
            background=1a1f28e6
            text=e0e0e0ff
            match=81a1c1ff
            selection=363a4fff
            selection-text=e0e0e0ff
            border=404040ff

            [border]
            width=1
            radius=${toString node.gui.fuzzel.borderRadius}
          '';
        in
        {
          environment.systemPackages = [ pkgs.fuzzel ];
          environment.etc."xdg/fuzzel/fuzzel.ini".source = fuzzelConfig;
        }
      );
  };
}
