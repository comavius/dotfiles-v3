{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  colors = config.lib.stylix.colors;
  hyprlandSessionTarget = config.wayland.systemd.target;
  kaleido = inputs.kaleido.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [
    kaleido
    pkgs.windowtolayer
  ];

  systemd.user.services.kaleido = {
    Unit = {
      Description = "Kaleido layer wallpaper";
      After = [ hyprlandSessionTarget ];
      PartOf = [ hyprlandSessionTarget ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = lib.escapeShellArgs [
        (lib.getExe pkgs.windowtolayer)
        "--maximized"
        "--"
        (lib.getExe' kaleido "kaleido")
        "hex-flip"
        colors.base01
        colors.base04
      ];
      Environment = [ "WINIT_UNIX_BACKEND=wayland" ];
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = [ hyprlandSessionTarget ];
  };
}
