{ lib, ... }:
{
  modules.base = {
    options.boot = {
      kernelPackages = lib.mkOption {
        type = lib.types.str;
        default = "linuxPackages_latest";
        description = "Kernel packages to use";
        example = "linuxPackages_zen";
      };
      loader = {
        systemd-boot.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        timeout = lib.mkOption {
          type = lib.types.int;
          default = 1;
        };
        efi.canTouchEfiVariables = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
      initrd = {
        systemd.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        availableKernelModules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
      kernelModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      kernelParams = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      extraModulePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra kernel module packages (as strings)";
      };
      sysctl = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };
      tmp = {
        useTmpfs = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        tmpfsHugeMemoryPages = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        tmpfsSize = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "50%";
        };
      };
      plymouth.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      enableContainers = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    module =
      {
        node,
        pkgs,
        config,
        lib,
        ...
      }:
      let
        cfg = node.base.boot;
      in
      {
        boot = {
          consoleLogLevel = 3;
          kernelPackages = lib.mkDefault pkgs.${cfg.kernelPackages};
          kernelModules = cfg.kernelModules;
          kernelParams = cfg.kernelParams ++ [ "quiet" ];
          extraModulePackages = map (p: config.boot.kernelPackages.${p}) cfg.extraModulePackages;
          kernel.sysctl = cfg.sysctl;

          loader = {
            systemd-boot.enable = cfg.loader.systemd-boot.enable;
            timeout = cfg.loader.timeout;
            efi.canTouchEfiVariables = cfg.loader.efi.canTouchEfiVariables;
          };

          initrd = {
            systemd.enable = cfg.initrd.systemd.enable;
            availableKernelModules = cfg.initrd.availableKernelModules;
          };

          tmp = {
            useTmpfs = cfg.tmp.useTmpfs;
            tmpfsHugeMemoryPages = node.base.boot.tmp.tmpfsHugeMemoryPages;
            cleanOnBoot = lib.mkDefault (!config.boot.tmp.useTmpfs);
          }
          // lib.optionalAttrs (cfg.tmp.tmpfsSize != null) {
            tmpfsSize = cfg.tmp.tmpfsSize;
          };

          plymouth.enable = cfg.plymouth.enable;
          enableContainers = lib.mkDefault cfg.enableContainers;
        };
      };
  };
}
