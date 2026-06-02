{ config, ... }:
let
  homeDirectory = config.homeDirectory;
in
{
  username = "comavius";
  hostname = "usami";
  dotfilesRepositoryPath = "${homeDirectory}/projects/dotfiles-v3";
  hasNvidiaGpu = true;

  disk.configSource = "hardware-configuration.nix";
  disk.hardware-configuration = import ./usami/hardware-configuration.nix;
}
