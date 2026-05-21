{
  config,
  pkgs,
  ...
}:
let
  cfg = config.my;
in
{
  home = {
    username = cfg.username;
    homeDirectory = cfg.homeDirectory;
    stateVersion = cfg.stateVersion;
  };

  programs.home-manager.enable = true;

  programs.kitty.enable = true;
  programs.wofi.enable = true;
  programs.waybar.enable = true;

  services.hypridle.enable = true;
  services.mako.enable = true;

  programs.hyprlock.enable = true;
  programs.wlogout.enable = true;

  home.packages = with pkgs; [
    hyprland-autoname-workspaces
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    extraConfig = ''
      monitor = , preferred, auto, 1

      $mod = SUPER
      $terminal = ${pkgs.kitty}/bin/kitty

      input {
          kb_layout = jp
      }

      input:touchpad {
          natural_scroll = true
      }

      general {
          resize_on_border = true
      }

      decoration {
          active_opacity = 1.0
          inactive_opacity = 1.0
          fullscreen_opacity = 1.0
      }

      misc {
          force_default_wallpaper = 1
          disable_hyprland_logo = true
      }

      cursor {
          inactive_timeout = 60
      }

      dwindle {
          preserve_split = true
      }

      exec-once = ${pkgs.waybar}/bin/waybar
      exec-once = ${pkgs.mako}/bin/mako
      exec-once = ${pkgs.hyprland-autoname-workspaces}/bin/hyprland-autoname-workspaces
      exec-once = ${pkgs.kitty}/bin/kitty --title hyprland-ready ${pkgs.zsh}/bin/zsh -lc 'echo "Hyprland is running."; echo "Super+Return opens a terminal."; exec ${pkgs.zsh}/bin/zsh'

      bind = $mod, Return, exec, $terminal
      bind = $mod Shift, q, killactive
      bind = $mod, d, exec, ${pkgs.wofi}/bin/wofi --show drun
      bind = $mod, s, setfloating
      bind = $mod, w, settiled
      bind = $mod, e, togglesplit
      bind = $mod, f, fullscreen, toggle

      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10

      bind = $mod Shift, 1, movetoworkspace, 1
      bind = $mod Shift, 2, movetoworkspace, 2
      bind = $mod Shift, 3, movetoworkspace, 3
      bind = $mod Shift, 4, movetoworkspace, 4
      bind = $mod Shift, 5, movetoworkspace, 5
      bind = $mod Shift, 6, movetoworkspace, 6
      bind = $mod Shift, 7, movetoworkspace, 7
      bind = $mod Shift, 8, movetoworkspace, 8
      bind = $mod Shift, 9, movetoworkspace, 9
      bind = $mod Shift, 0, movetoworkspace, 10

      bindm = $mod, mouse:272, movewindow
    '';
  };
}
