# modules/base/nix.nix
{ lib, ... }:
{
  modules.base = {
    options.nix = {
      substituters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      trustedPublicKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      trustedUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "@wheel" ];
      };
      experimentalFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "nix-command"
          "flakes"
          "ca-derivations"
          "auto-allocate-uids"
          "cgroups"
          "no-url-literals"
          "pipe-operators"
        ];
      };
      gc = {
        automatic = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        dates = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
        };
        options = lib.mkOption {
          type = lib.types.str;
          default = "--delete-older-than 30d";
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
      {
        nix = {
          package = pkgs.nixVersions.latest;
          channel.enable = false;
          settings = {
            flake-registry = "/etc/nix/json";
            nix-path = [ "nixpkgs=${pkgs.path}" ];
            substituters = node.base.nix.substituters;
            trusted-public-keys = node.base.nix.trustedPublicKeys;
            trusted-users = node.base.nix.trustedUsers;
            pure-eval = true;
            auto-optimise-store = true;
            builders-use-substitutes = true;
            keep-derivations = true;
            auto-allocate-uids = true;
            use-cgroups = true;
            use-xdg-base-directories = true;
            experimental-features = node.base.nix.experimentalFeatures;
          };
          gc = lib.mkIf node.base.nix.gc.automatic {
            automatic = true;
            dates = node.base.nix.gc.dates;
            options = node.base.nix.gc.options;
          };
        };
      };
  };
}
