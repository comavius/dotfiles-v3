{ config, ... }:
let
  homeDirectory = config.homeDirectory;
in
{
  username = "comavius";
  hostname = "maeriberry";
  dotfilesRepositoryPath = "${homeDirectory}/projects/dotfiles-v3";
  hasNvidiaGpu = false;

  modules = [ ./maeriberry/hardware-configuration.nix ];

  disk.configSource = "disko";
  disk.disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
              ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/run/maeriberry-luks-password";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
