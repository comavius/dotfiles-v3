{ lib }:
{
  module =
    { config, name, ... }:
    {
      options = {
        system = lib.mkOption {
          type = lib.types.str;
          default = "x86_64-linux";
          description = "System type for this NixOS host.";
        };

        username = lib.mkOption {
          type = lib.types.str;
          description = "Primary user name for this NixOS host.";
        };

        homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/${config.username}";
          description = "Home directory for the primary user.";
        };

        dotfilesRepositoryPath = lib.mkOption {
          type = lib.types.str;
          description = "Local path to this dotfiles repository.";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Host name.";
        };

        stateVersion = lib.mkOption {
          type = lib.types.str;
          default = "26.05";
          description = "NixOS and Home Manager state version.";
        };

        hasNvidiaGpu = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this host has an NVIDIA GPU.";
        };

        isVm = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this host is virtual machine or not.";
        };

        initialPassword = lib.mkOption {
          type = lib.types.str;
          default = "nixos";
          description = "Initial password for the primary user.";
        };

        disk = {
          configSource = lib.mkOption {
            type = lib.types.enum [
              "disko"
              "hardware-configuration.nix"
            ];
            default = "disko";
            description = "Source used to configure disks in the NixOS system.";
          };
          hardware-configuration = lib.mkOption {
            type = lib.types.nullOr lib.types.deferredModule;
            default = null;
            description = "Generated hardware-configuration.nix module for this host.";
          };
          disko = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Disko configuration for this host.";
          };
        };

        zramSwapSizeGiB = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          description = "Zram swap size in GiB. Disabled when null.";
        };

        modules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
          description = "Additional NixOS modules for this host.";
        };

        homeModules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
          description = "Additional Home Manager modules for this host's primary user.";
        };
      };
    };
}
