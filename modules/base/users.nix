{ lib, ... }:
{
  modules.base = {
    options.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            hashedPassword = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            extraGroups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "wheel" ];
            };
            shell = lib.mkOption {
              type = lib.types.str;
              default = "bash";
            };
            packages = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            authorizedKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            linger = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            homeFiles = lib.mkOption {
              type = lib.types.attrsOf lib.types.path;
              default = { };
              description = "Files/directories to symlink into home (recursively)";
              example = lib.literalExpression ''
                {
                  ".config/nvim" = ./nvim;
                  ".zshrc" = pkgs.writeText "zshrc" "alias ll='ls -la'";
                }
              '';
            };
          };
        }
      );
      default = { };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      let
        readDirRecursive =
          dir:
          lib.pipe (builtins.readDir dir) [
            (lib.mapAttrsToList (
              name: type:
              if type == "directory" then
                map (p: "${name}/${p}") (readDirRecursive (dir + "/${name}"))
              else
                [ name ]
            ))
            lib.flatten
          ];

        mkUserRules =
          username: userCfg:
          lib.pipe userCfg.homeFiles [
            (lib.mapAttrsToList (
              target: source:
              let
                sourceType = builtins.readFileType source;
              in
              if sourceType == "directory" then
                map (relPath: "L+ %h/${target}/${relPath} - - - - ${source}/${relPath}") (readDirRecursive source)
              else
                [ "L+ %h/${target} - - - - ${source}" ]
            ))
            lib.flatten
          ];
      in
      lib.mkIf (node.base.users != { }) {
        users.mutableUsers = false;

        users.users = lib.mapAttrs (username: userCfg: {
          isNormalUser = true;
          inherit (userCfg) hashedPassword extraGroups linger;
          packages = map (p: pkgs.${p}) userCfg.packages;
          shell = pkgs.${userCfg.shell};
          openssh.authorizedKeys.keys = userCfg.authorizedKeys;
        }) node.base.users;

        systemd.user.tmpfiles.users = lib.mapAttrs (username: userCfg: {
          rules = mkUserRules username userCfg;
        }) (lib.filterAttrs (_: u: u.homeFiles != { }) node.base.users);
      };
  };
}
