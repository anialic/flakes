{ lib, inputs, ... }:
{
  modules.preservation = {
    target = "nixos";

    options = {
      persistPath = lib.mkOption {
        type = lib.types.str;
        default = "/persist";
      };
      users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              files = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
              directories = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.either lib.types.str (
                    lib.types.submodule {
                      options = {
                        directory = lib.mkOption { type = lib.types.str; };
                        mode = lib.mkOption {
                          type = lib.types.str;
                          default = "0755";
                        };
                      };
                    }
                  )
                );
                default = [ ];
              };
            };
          }
        );
        default = { };
      };
    };

    module =
      { node, lib, ... }:
      {
        imports = [ inputs.preservation.nixosModules.preservation ];

        config = lib.mkIf node.preservation.enable {
          preservation = {
            enable = true;
            preserveAt.${node.preservation.persistPath} = {
              users = lib.mapAttrs (username: userCfg: {
                inherit (userCfg) files;
                directories = map (
                  d: if builtins.isString d then d else { inherit (d) directory mode; }
                ) userCfg.directories;
              }) node.preservation.users;
            };
          };
        };
      };
  };
}
