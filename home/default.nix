{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my;
  dotfilesRepositoryUpdater = pkgs.writeShellApplication {
    name = "dotfiles-repository-updater";
    runtimeInputs = [ pkgs.git ];
    text = ''
      repo=${lib.escapeShellArg cfg.dotfilesRepositoryPath}

      if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        exit 0
      fi

      git -C "$repo" fetch --prune origin "+refs/heads/*:refs/remotes/origin/*"
    '';
  };
in
{
  imports = [
    ./hyprland
    ./waybar
    ./zsh.nix
    ./fcitx.nix
    ./home-packages.nix
    ./xdg.nix
  ];
  nix.registry.dots.flake = inputs.self;

  home = {
    username = cfg.username;
    homeDirectory = cfg.homeDirectory;
    stateVersion = cfg.stateVersion;
  };

  programs.home-manager.enable = true;

  systemd.user.services.dotfiles-repository-update = {
    Unit.Description = "Update local dotfiles repository refs";
    Service = {
      Type = "oneshot";
      ExecStart = "${dotfilesRepositoryUpdater}/bin/dotfiles-repository-updater";
    };
  };

  systemd.user.timers.dotfiles-repository-update = {
    Unit.Description = "Update local dotfiles repository refs periodically";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

}
