{
  pkgs,
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

  home.packages = with pkgs; [
    bottom
    gping
    dive
    fastfetch
    zellij
    firefox
    nixd
    obs-studio
    libreoffice
    go
    go-tools
    clang-tools
    poppler-utils
    wl-clipboard
    vscode
    discord
    google-chrome
  ];
}
