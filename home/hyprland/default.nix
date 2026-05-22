{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;

  replacementRule = {
    "@hyprland-autoname-workspaces@" =
      "${pkgs.hyprland-autoname-workspaces}/bin/hyprland-autoname-workspaces";
    "@kitty@" = "${pkgs.kitty}/bin/kitty";
    "@mako@" = "${pkgs.mako}/bin/mako";
    "@waybar@" = "${pkgs.waybar}/bin/waybar";
    "@wofi@" = "${pkgs.wofi}/bin/wofi";
    "@zsh@" = "${pkgs.zsh}/bin/zsh";
  };

  replaceFrom = lib.foldlAttrs (
    acc: from: _:
    acc ++ [ from ]
  ) [ ] replacementRule;
  replaceTo = lib.foldlAttrs (
    acc: _: to:
    acc ++ [ to ]
  ) [ ] replacementRule;

  readWithReplacement = path: lib.replaceStrings replaceFrom replaceTo (builtins.readFile path);

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

    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland.enable = true;
      extraConfig = lib.mkMerge [
        (lib.mkOrder 1000 (readWithReplacement ./00-env.conf))
        (lib.mkOrder 1010 (readWithReplacement ./10-input.conf))
        (lib.mkOrder 1020 (readWithReplacement ./20-appearance.conf))
        (lib.mkOrder 1030 (readWithReplacement ./30-autostart.conf))
        (lib.mkOrder 1040 (readWithReplacement ./40-binds.conf))
      ];
    };
  }
  (lib.mkIf cfg.hasNvidiaGpu {
    wayland.windowManager.hyprland.extraConfig = lib.mkOrder 1005 (
      readWithReplacement ./05-nvidia.conf
    );
  })
  (lib.mkIf (!cfg.isVm) {
    wayland.windowManager.hyprland.extraConfig = lib.mkOrder 1039 (
      readWithReplacement ./39-modkey.conf
    );
  })
  (lib.mkIf cfg.isVm {
    wayland.windowManager.hyprland.extraConfig = lib.mkOrder 1039 (
      readWithReplacement ./39-modkey-vm.conf
    );
  })
]
