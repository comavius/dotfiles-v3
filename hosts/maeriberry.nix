{ config, ... }:
let
  homeDirectory = config.homeDirectory;
in
{
  username = "comavius";
  hostname = "maeriberry";
  dotfilesRepositoryPath = "${homeDirectory}/projects/dotfiles-v3";
  hasNvidiaGpu = false;

  disk.configSource = "hardware-configuration.nix";
  disk.hardware-configuration = import ./maeriberry/hardware-configuration.nix;
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
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
