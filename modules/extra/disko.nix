{ lib, inputs, ... }:
{
  modules.disko = {
    options = {
      diskPath = lib.mkOption {
        type = lib.types.str;
        default = "/dev/sda";
      };
      swapSize = lib.mkOption {
        type = lib.types.str;
        default = "16G";
      };
    };

    module =
      { node, lib, ... }:
      {
        imports = [ inputs.disko.nixosModules.disko ];

        config = lib.mkIf node.disko.enable {
          disko.devices.nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "defaults"
              "mode=755"
              "nodev"
              "nosuid"
            ];
          };
          disko.devices.disk.main = {
            type = "disk";
            device = node.disko.diskPath;
            content.type = "gpt";
            content.partitions = {
              ESP = {
                size = "1000M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0077"
                    "dmask=0077"
                  ];
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  settings = {
                    allowDiscards = true;
                    bypassWorkqueues = true;
                  };
                };
                content.content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "noatime"
                        "compress-force=zstd"
                        "space_cache=v2"
                      ];
                    };
                    "/tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [
                        "noatime"
                        "compress-force=zstd"
                        "space_cache=v2"
                      ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "noatime"
                        "compress-force=zstd"
                        "space_cache=v2"
                      ];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      mountOptions = [
                        "noatime"
                        "compress-force=zstd"
                        "space_cache=v2"
                      ];
                      swap.swapfile.size = node.disko.swapSize;
                    };
                  };
                };
              };
            };
          };
        };
      };
  };
}
