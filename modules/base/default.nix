{ lib, ... }:
let
  pkgsDir = ./_pkgs;
  hasPkgsDir = builtins.pathExists pkgsDir;

  overlay =
    final: prev:
    if !hasPkgsDir then
      { }
    else
      builtins.readDir pkgsDir
      |> lib.filterAttrs (
        n: v:
        (v == "regular" && lib.hasSuffix ".nix" n)
        || (v == "directory" && builtins.pathExists (pkgsDir + "/${n}/default.nix"))
      )
      |> lib.mapAttrs (n: _: final.callPackage (pkgsDir + "/${n}") { })
      |> lib.mapAttrs' (n: v: lib.nameValuePair (lib.removeSuffix ".nix" n) v);
in
{
  modules.base = {
    target = "nixos";

    options = {
      stateVersion = lib.mkOption {
        type = lib.types.str;
        default = "25.11";
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "UTC";
      };
      locale = lib.mkOption {
        type = lib.types.str;
        default = "C.UTF-8";
      };
      keyMap = lib.mkOption {
        type = lib.types.str;
        default = "us";
      };
      hostName = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      dns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "1.1.1.1"
          "2606:4700:4700::1111"
          "8.8.8.8"
          "2001:4860:4860::8888"
        ];
      };
      wheelNeedsPassword = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      systemPackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "System packages to install (as attribute names)";
      };
      sessionVariables = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment session variables";
      };
      notDetected.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Import hardware scan not-detected.nix module";
      };
      tpm2.enable = lib.mkEnableOption "TPM2 support";
      zram = {
        enable = lib.mkEnableOption "zram swap";
        algorithm = lib.mkOption {
          type = lib.types.str;
          default = "zstd";
        };
        size = lib.mkOption {
          type = lib.types.str;
          default = "ram";
        };
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        name,
        system,
        modulesPath,
        ...
      }:
      {
        imports = lib.optional node.base.notDetected.enable (
          modulesPath + "/installer/scan/not-detected.nix"
        );

        nixpkgs.overlays = [ overlay ];
        nixpkgs.hostPlatform = system;
        nixpkgs.config.allowUnfree = true;

        time.timeZone = node.base.timeZone;
        i18n.defaultLocale = node.base.locale;
        console.keyMap = node.base.keyMap;

        networking.hostName = if node.base.hostName != "" then node.base.hostName else name;

        environment.etc = {
          "resolv.conf".text = node.base.dns |> map (d: "nameserver ${d}") |> lib.concatStringsSep "\n";
          "machine-id".text = "b08dfa6083e7567a1921a715000001fb\n";
        };

        system = {
          stateVersion = node.base.stateVersion;
          etc.overlay.enable = true;
          etc.overlay.mutable = false;
          nixos-init.enable = true;
        };

        security = {
          polkit.enable = true;
          sudo-rs = {
            enable = true;
            execWheelOnly = true;
            wheelNeedsPassword = node.base.wheelNeedsPassword;
          };
          tpm2 = lib.mkIf node.base.tpm2.enable {
            enable = true;
            pkcs11.enable = true;
            tctiEnvironment.enable = true;
          };
        };

        environment = {
          stub-ld.enable = false;
          defaultPackages = lib.mkDefault [ ];
          systemPackages = map (p: pkgs.${p}) node.base.systemPackages;
          sessionVariables = node.base.sessionVariables;
        };

        services = {
          resolved.enable = false;
          userborn.enable = true;
          dbus.implementation = "broker";
          zram-generator = lib.mkIf node.base.zram.enable {
            enable = true;
            settings.zram0 = {
              compression-algorithm = node.base.zram.algorithm;
              zram-size = node.base.zram.size;
            };
          };
        };

        documentation = {
          doc.enable = false;
          info.enable = false;
          nixos.enable = false;
          man.generateCaches = false;
        };
      };
  };
}
