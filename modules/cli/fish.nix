{ lib, ... }:
{
  modules.cli = {
    options.fish = {
      enable = lib.mkEnableOption "fish shell";
      flakePath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        name,
        ...
      }:
      lib.mkIf node.cli.fish.enable {
        environment.systemPackages = [ pkgs.fishPlugins.tide ];
        programs.fish =
          let
            tide = pkgs.fishPlugins.tide.src;
            flake = if node.cli.fish.flakePath != null then node.cli.fish.flakePath else ".";
            flakeRef = "${flake}#${name}";
          in
          {
            enable = true;
            shellInit = ''
              set fish_greeting
              function fish_user_key_bindings
                fish_vi_key_bindings
                bind f accept-autosuggestion
              end
              string replace -r '^' 'set -g ' < ${tide}/functions/tide/configure/icons.fish | source
              string replace -r '^' 'set -g ' < ${tide}/functions/tide/configure/configs/lean.fish | source
              string replace -r '^' 'set -g ' < ${tide}/functions/tide/configure/configs/lean_16color.fish | source
              set -g tide_prompt_add_newline_before false
              fish_config theme choose fish\ default
              set fish_color_autosuggestion white
            '';
            shellAbbrs = {
              rebuild = "nixos-rebuild --sudo -L --flake ${flakeRef}";
            };
          };
      };
  };
}
