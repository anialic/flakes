{ lib, ... }:
{
  modules.cli = {
    options.git = {
      enable = lib.mkEnableOption "Git";
      userName = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Git user name";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Git user email";
      };
      defaultBranch = lib.mkOption {
        type = lib.types.str;
        default = "main";
      };
      lfs = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Git LFS";
      };
      signing = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable commit signing";
        };
        key = lib.mkOption {
          type = lib.types.str;
          default = "~/.ssh/id_ed25519";
          description = "Path to signing key";
        };
        format = lib.mkOption {
          type = lib.types.str;
          default = "ssh";
          description = "Signing format (ssh or gpg)";
        };
      };
      pull = {
        rebase = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
      merge = {
        conflictStyle = lib.mkOption {
          type = lib.types.str;
          default = "diff3";
        };
        tool = lib.mkOption {
          type = lib.types.str;
          default = "vimdiff";
        };
      };
      extraConfig = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional git configuration";
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      lib.mkIf node.cli.git.enable (
        let
          cfg = node.cli.git;

          gitPackage = if cfg.lfs then pkgs.git-lfs else pkgs.git;

          baseConfig = {
            init.defaultBranch = cfg.defaultBranch;
            pull.rebase = cfg.pull.rebase;
            merge = {
              conflictStyle = cfg.merge.conflictStyle;
              tool = cfg.merge.tool;
            };
            mergetool = {
              keepBackup = false;
              keepTemporaries = false;
              writeToTemp = true;
            };
            fetch.prune = true;
            credential.helper = "store";
          };

          userConfig = lib.optionalAttrs (cfg.userName != "" && cfg.userEmail != "") {
            user = {
              name = cfg.userName;
              email = cfg.userEmail;
            };
          };

          signingConfig = lib.optionalAttrs cfg.signing.enable {
            commit.gpgSign = true;
            gpg.format = cfg.signing.format;
            user.signingKey = cfg.signing.key;
          };
        in
        {
          programs.git = {
            enable = true;
            package = gitPackage;
            config = lib.mkMerge [
              baseConfig
              userConfig
              signingConfig
              cfg.extraConfig
            ];
          };

          environment.systemPackages = lib.optionals cfg.lfs [ pkgs.git-lfs ];
        }
      );
  };
}
