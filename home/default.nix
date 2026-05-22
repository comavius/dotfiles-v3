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
    ./waybar
  ];

  home = {
    username = cfg.username;
    homeDirectory = cfg.homeDirectory;
    stateVersion = cfg.stateVersion;
  };

  programs.home-manager.enable = true;
}
