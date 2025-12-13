{ lib, ... }:
{
  modules.gui = {
    options.foot = {
      enable = lib.mkEnableOption "Foot terminal";
      font = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font:size=8";
      };
      alpha = lib.mkOption {
        type = lib.types.float;
        default = 0.65;
      };
      padding = lib.mkOption {
        type = lib.types.str;
        default = "10x10 center";
      };
    };
    module =
      { node, lib, ... }:
      lib.mkIf (node.gui.enable && node.gui.foot.enable) {
        programs.foot = {
          enable = true;
          settings = {
            main = {
              dpi-aware = "yes";
              font = node.gui.foot.font;
              pad = node.gui.foot.padding;
              term = "xterm-256color";
            };
            mouse.hide-when-typing = "yes";
            colors = {
              alpha = node.gui.foot.alpha;
              foreground = "d9e0ee";
              background = "000000";
              cursor = "2e3440 d9e0ee";
              selection-foreground = "d8dee9";
              selection-background = "4c566a";
              regular0 = "3b4252";
              regular1 = "aa6e6e";
              regular2 = "a3be8c";
              regular3 = "aca99c";
              regular4 = "6e85aa";
              regular5 = "aa6e8d";
              regular6 = "b5d5d0";
              regular7 = "d9e0ee";
              bright0 = "4c566a";
              bright1 = "bf616a";
              bright2 = "a3be8c";
              bright3 = "ebcb8b";
              bright4 = "81a1c1";
              bright5 = "b48ead";
              bright6 = "8fbcbb";
              bright7 = "eceff4";
              dim0 = "373e4d";
              dim1 = "94545d";
              dim2 = "809575";
              dim3 = "b29e75";
              dim4 = "68809a";
              dim5 = "8c738c";
              dim6 = "6d96a5";
              dim7 = "aeb3bb";
            };
            cursor = {
              style = "block";
              blink = "yes";
            };
          };
        };
      };
  };
}
