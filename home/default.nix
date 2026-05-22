{
  config,
  ...
}:
let
  cfg = config.my;
in
{
  imports = [
    ./hyprland
  ];

  home = {
    username = cfg.username;
    homeDirectory = cfg.homeDirectory;
    stateVersion = cfg.stateVersion;
  };

  programs.home-manager.enable = true;
}
