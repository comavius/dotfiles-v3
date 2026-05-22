{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;
  confDirectory = "${config.home.homeDirectory}/.config/hypr/conf";
  confTargetDirectory = ".config/hypr/conf";

  replacements = {
    "@hyprland-autoname-workspaces@" =
      "${pkgs.hyprland-autoname-workspaces}/bin/hyprland-autoname-workspaces";
    "@kitty@" = "${pkgs.kitty}/bin/kitty";
    "@mako@" = "${pkgs.mako}/bin/mako";
    "@waybar@" = "${pkgs.waybar}/bin/waybar";
    "@wofi@" = "${pkgs.wofi}/bin/wofi";
    "@zsh@" = "${pkgs.zsh}/bin/zsh";
  };

  renderConf =
    path:
    lib.replaceStrings (lib.attrNames replacements) (lib.attrValues replacements) (
      builtins.readFile path
    );

  baseConfFiles = {
    "00-env.conf" = ./00-env.conf;
    "05-nvidia.conf" = null;
    "10-input.conf" = ./10-input.conf;
    "20-appearance.conf" = ./20-appearance.conf;
    "30-autostart.conf" = ./30-autostart.conf;
    "40-binds.conf" = ./40-binds.conf;
  };

  sourceLine = name: "source = ${confDirectory}/${name}";
in
lib.mkMerge [
  {
    programs.kitty.enable = true;
    programs.wofi.enable = true;
    programs.waybar.enable = true;

    services.hypridle.enable = true;
    services.mako.enable = true;

    programs.hyprlock.enable = true;
    programs.wlogout.enable = true;

    home = {
      packages = with pkgs; [
        hyprland-autoname-workspaces
      ];

      file = lib.mapAttrs' (
        name: path:
        lib.nameValuePair "${confTargetDirectory}/${name}" {
          text = if path == null then lib.mkDefault "" else renderConf path;
        }
      ) baseConfFiles;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland.enable = true;
      extraConfig = lib.concatStringsSep "\n" (map sourceLine (lib.attrNames baseConfFiles));
    };
  }

  (lib.mkIf cfg.hasNvidiaGpu {
    home.file."${confTargetDirectory}/05-nvidia.conf".text = renderConf ./05-nvidia.conf;
  })
]
