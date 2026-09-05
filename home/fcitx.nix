{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  mozkey-fcitx5 = pkgs.callPackage ../pkgs/mozkey.nix {
    inherit (inputs) nixpkgs;
  };
  hyprlandSessionTarget = config.wayland.systemd.target;
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [
        mozkey-fcitx5
      ];
      waylandFrontend = true;
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "jp";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0".Name = "keyboard-jp";
        "Groups/0/Items/1".Name = "mozc";
      };
    };
  };

  systemd.user.services.mozkey-zenz = lib.mkIf (config.my.hostname == "usami") {
    Unit = {
      Description = "Mozkey local Zenz correction runtime";
      After = [ hyprlandSessionTarget ];
      PartOf = [ hyprlandSessionTarget ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${mozkey-fcitx5}/lib/mozc/ZenzRuntime/mozc_zenz_scorer";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = [ hyprlandSessionTarget ];
  };
}
