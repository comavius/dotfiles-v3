{ config, ... }:
let
  cfg = config.my;
in
{
  networking = {
    hostName = cfg.hostname;
    networkmanager.enable = true;
  };

  system.stateVersion = cfg.stateVersion;

  users.users."${cfg.username}" = {
    initialPassword = cfg.initialPassword;
  };
}
