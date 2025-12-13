{ lib, inputs, ... }:
{
  modules.lanzaboote = {
    target = "nixos";

    options = {
      pkiBundle = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/sbctl";
      };
    };

    module =
      { node, lib, ... }:
      lib.mkIf node.lanzaboote.enable {
        imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
        boot = {
          loader.systemd-boot.enable = lib.mkForce false;
          lanzaboote = {
            enable = true;
            pkiBundle = node.lanzaboote.pkiBundle;
          };
        };
      };
  };
}
