{ resource, ... }:
{
  nodes.alice = {
    system = "aarch64-linux";
    apple = {
      enable = true;
      peripheralFirmwareDirectory = resource + "/firmware";
    };

    base = {
      enable = true;
      stateVersion = "25.11";
      timeZone = "Asia/Shanghai";
      hostName = "alice";

      fonts.enable = true;

      network = {
        wired.enable = false;
        wireless.enable = true;
      };

      boot = {
        kernelParams = [
          "zswap.enabled=1"
          "zswap.compressor=zstd"
          "zswap.max_pool_percent=25"
          "zswap.zpool=zsmalloc"
        ];
        tmp = {
          useTmpfs = true;
          tmpfsHugeMemoryPages = "always";
        };
      };

      disks = {
        enable = true;
        luks = {
          enable = true;
          device = "/dev/disk/by-uuid/91ba647e-7ccd-4fb4-ab3c-867e81d42a76";
        };
        boot.device = "/dev/disk/by-uuid/274C-19EB";
        swap.enable = true;
      };

      nix = {
        gc.automatic = true;
        gc.dates = "weekly";
        gc.options = "--delete-older-than 7d";
        substituters = [
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://nixos-apple-silicon.cachix.org"
        ];
        trustedPublicKeys = [
          "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
        ];
      };
      users.alice = {
        hashedPassword = "$y$j9T$0cTyUEdwuAAGx9kxGb0P3.$xZI6SLqHN.QJbSrSzdvhialybb6RFmvJ/aMtXq04cn1";
        extraGroups = [
          "wheel"
          "video"
        ];
        shell = "fish";
        packages = [
          "qutebrowser"
          "zed-editor"
          "mpv"
          "vim"
          "seahorse"
          "git"
        ];
      };
    };

    cli = {
      enable = true;
      fish = {
        enable = true;
        flakePath = "/home/alice/Projects/flakes";
      };

      git = {
        enable = true;
        userName = "Cuer";
        userEmail = "i@cuer.org";
      };

      neovim.enable = true;
      neovim.transparent = true;
    };

    gui = {
      enable = true;
      niri = {
        enable = true;
        username = "alice";
      };
      fcitx5.enable = true;
      mako.enable = true;
      waybar.enable = true;
      fuzzel.enable = true;
      foot.enable = true;
      firefox.enable = true;
    };

    proxy = {
      enable = true;
      singbox = {
        enable = true;
        configFile = resource + "/singbox.json";
      };
    };

    preservation = {
      enable = true;
      users.alice = {
        files = [ ];
        directories = [
          "Documents"
          "Downloads"
          "Pictures"
          "Projects"
          ".config/fcitx5"
          ".local/share/PrismLauncher"
          ".local/share/fish"
          {
            directory = ".ssh";
            mode = "0700";
          }
          {
            directory = ".gnupg";
            mode = "0700";
          }
        ];
      };
    };
  };
}
