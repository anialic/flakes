{ lib, ... }:
{
  modules.base = {
    options.disks = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable disk configuration (disable if using disko)";
      };
      luks = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        device = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "LUKS device path, e.g., /dev/disk/by-uuid/...";
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "root";
        };
      };
      boot = {
        device = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Boot partition device, e.g., /dev/disk/by-uuid/...";
        };
        fsType = lib.mkOption {
          type = lib.types.str;
          default = "vfat";
        };
        options = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "fmask=0022"
            "dmask=0022"
          ];
        };
      };
      root = {
        useTmpfs = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use tmpfs for root filesystem";
        };
        tmpfsSize = lib.mkOption {
          type = lib.types.str;
          default = "2G";
        };
      };
      btrfs = {
        device = lib.mkOption {
          type = lib.types.str;
          default = "/dev/mapper/root";
        };
        options = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "noatime"
            "compress=zstd"
            "space_cache=v2"
          ];
        };
        subvolumes = {
          nix = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          persist = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          swap = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          tmp = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      };
      swap = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        path = lib.mkOption {
          type = lib.types.str;
          default = "/swap/swapfile";
        };
      };
    };

    module =
      { node, lib, ... }:
      lib.mkIf (node.base.enable && node.base.disks.enable) (
        let
          cfg = node.base.disks;
        in
        {
          boot.initrd.luks.devices.${cfg.luks.name} = lib.mkIf cfg.luks.enable {
            device = cfg.luks.device;
          };

          fileSystems."/" =
            if cfg.root.useTmpfs then
              {
                fsType = "tmpfs";
                options = [
                  "defaults"
                  "mode=755"
                  "nodev"
                  "nosuid"
                  "size=${cfg.root.tmpfsSize}"
                ];
              }
            else
              {
                device = cfg.btrfs.device;
                fsType = "btrfs";
                options = [ "subvol=root" ] ++ cfg.btrfs.options;
              };

          fileSystems."/boot" = {
            device = cfg.boot.device;
            fsType = cfg.boot.fsType;
            options = lib.mkIf (cfg.boot.fsType == "vfat") cfg.boot.options;
          };

          fileSystems."/nix" = lib.mkIf cfg.btrfs.subvolumes.nix {
            device = cfg.btrfs.device;
            fsType = "btrfs";
            options = [ "subvol=nix" ] ++ cfg.btrfs.options;
          };

          fileSystems."/persist" = lib.mkIf cfg.btrfs.subvolumes.persist {
            device = cfg.btrfs.device;
            fsType = "btrfs";
            options = [ "subvol=persist" ] ++ cfg.btrfs.options;
            neededForBoot = true;
          };

          fileSystems."/swap" = lib.mkIf cfg.btrfs.subvolumes.swap {
            device = cfg.btrfs.device;
            fsType = "btrfs";
            options = [ "subvol=swap" ] ++ cfg.btrfs.options;
            neededForBoot = true;
          };

          fileSystems."/tmp" = lib.mkIf cfg.btrfs.subvolumes.tmp {
            device = cfg.btrfs.device;
            fsType = "btrfs";
            options = [ "subvol=tmp" ] ++ cfg.btrfs.options;
          };

          swapDevices = lib.mkIf cfg.swap.enable [
            { device = cfg.swap.path; }
          ];
        }
      );
  };
}
