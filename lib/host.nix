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

        hostname = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Host name.";
        };

        stateVersion = lib.mkOption {
          type = lib.types.str;
          default = "25.11";
          description = "NixOS and Home Manager state version.";
        };

        hasNvidiaGpu = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this host has an NVIDIA GPU.";
        };

        initialPassword = lib.mkOption {
          type = lib.types.str;
          default = "nixos";
          description = "Initial password for the primary user.";
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
