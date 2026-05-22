{ config, lib, ... }:
let
  cfg = config.my;
in
{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  zramSwap = lib.mkIf (cfg.zramSwapSizeGiB != null) {
    enable = true;
    memoryMax = cfg.zramSwapSizeGiB * 1024 * 1024 * 1024;
    priority = 100;
  };

  networking = {
    hostName = cfg.hostname;
    networkmanager.enable = true;
  };

  system.stateVersion = cfg.stateVersion;

  users.users."${cfg.username}" = {
    initialPassword = cfg.initialPassword;
  };
}
