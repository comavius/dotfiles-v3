{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;
  colors = config.lib.stylix.colors.withHashtag;
  styleSource = pkgs.writeText "waybar-style-source.css" (
    lib.replaceStrings
      [
        "stylix-theme-base-color"
        "stylix-theme-text-color"
        "stylix-theme-bg-color"
        "stylix-theme-selected-bg-color"
        "stylix-error-color"
        "stylix-warning-color"
      ]
      [
        colors.base00
        colors.base05
        colors.base01
        colors.base0D
        colors.base08
        colors.base09
      ]
      (builtins.readFile ./style.css)
  );

  compiledStyle =
    pkgs.runCommand "waybar-style.css"
      {
        nativeBuildInputs = [ pkgs.nodejs ];
        NODE_PATH = "${pkgs.postcss}/lib/node_modules";
      }
      ''
        node ${./postcss-waybar-style.js} ${styleSource} "$out"
      '';

  screenRecordingStatus = pkgs.writeShellApplication {
    name = "waybar-screen-recording-status";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      unit="hypr-screen-record.service"

      if systemctl --user is-active --quiet "$unit"; then
        printf '{"text":"REC","class":"recording","tooltip":"Screen recording is running"}\n'
      else
        printf '{"text":"REC","class":"idle","tooltip":"Screen recording is stopped"}\n'
      fi
    '';
  };

  waybarPkgs = pkgs.callPackage ./pkgs {
    inherit (cfg) dotfilesRepositoryPath;
  };
  inherit (waybarPkgs)
    waybarAudioControl
    waybarNixosConfigurationStatus
    ;
in
{
  stylix.targets.waybar.enable = false;

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        height = 30;
        position = "top";
        reload_style_on_change = true;
        modules-left = [
          "custom/menu"
          "hyprland/workspaces"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "cpu"
          "memory"
          "battery"
          "network"
          "bluetooth"
          "pulseaudio"
          "backlight"
          "tray"
          "custom/nixos-configuration"
          "custom/screen-recording"
          "clock"
        ];
        "custom/menu" = {
          format = "";
          on-click = "${pkgs.wofi}/bin/wofi --show drun";
          tooltip = false;
        };
        "hyprland/workspaces" = {
          format = "{name}";
          persistent-workspaces = {
            "*" = [
              1
              2
              3
              4
              5
              6
              7
              8
              9
              10
            ];
          };
        };
        "hyprland/window" = {
          format = "{}";
          max-length = 80;
          separate-outputs = true;
        };
        cpu = {
          interval = 10;
          format = "󰘚";
          tooltip-format = "{usage}% used";
          states = {
            warning = 70;
            critical = 90;
          };
        };
        memory = {
          interval = 10;
          format = "󰍛";
          tooltip-format = "{used:0.1f}GiB/{total:0.1f}GiB";
          states = {
            warning = 70;
            critical = 90;
          };
        };
        battery = {
          interval = 30;
          states = {
            warning = 30;
            critical = 15;
          };
          format-charging = "󰂄 {capacity}%";
          format = "{icon} {capacity}%";
          format-icons = [
            "󱃍"
            "󰁺"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          tooltip = true;
        };
        network = {
          interval = 5;
          format-wifi = "{icon}";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          format-disabled = "󰀝";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          tooltip-format = "{ifname}: {ipaddr}";
          tooltip-format-wifi = "{ifname} ({essid}): {ipaddr}";
          tooltip-format-disconnected = "disconnected";
        };
        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          on-click-right = "rfkill toggle bluetooth";
          tooltip-format = "{}";
        };
        pulseaudio = {
          scroll-step = 5;
          format = "{icon} {volume}%";
          format-muted = "󰖁";
          format-icons = {
            headphone = "󰋋";
            headset = "󰋎";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          tooltip-format = "Volume: {volume}%\nLeft: output selector\nRight: mixer\nMiddle: restart audio";
          on-click = "${waybarAudioControl}/bin/waybar-audio-control";
          on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
          on-click-middle = "${waybarAudioControl}/bin/waybar-audio-control restart";
        };
        backlight = {
          format = "{icon} {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃠"
          ];
        };
        tray = {
          icon-size = 21;
          spacing = 5;
        };
        "custom/screen-recording" = {
          exec = "${screenRecordingStatus}/bin/waybar-screen-recording-status";
          interval = 1;
          return-type = "json";
          tooltip = true;
        };
        "custom/nixos-configuration" = {
          exec = "${waybarNixosConfigurationStatus}/bin/waybar-nixos-configuration-status";
          interval = 300;
          return-type = "json";
          tooltip = true;
        };
        clock = {
          interval = 60;
          format = "{:%e %b %Y %H:%M}";
          tooltip = true;
          tooltip-format = "<big>{:%B %Y}</big>\n<tt>{calendar}</tt>";
        };
      };
    };
  };

  xdg.configFile."waybar/style.css".source = compiledStyle;

  home.packages = with pkgs; [
    adwaita-icon-theme
    papirus-icon-theme
    pavucontrol
    waybarAudioControl
  ];
}
