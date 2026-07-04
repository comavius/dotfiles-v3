{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprlandSessionTarget = config.wayland.systemd.target;
  weylus = pkgs.callPackage ../pkgs/weylus.nix { };

  weylusHeadlessMonitor = pkgs.writeShellApplication {
    name = "weylus-headless-monitor";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      set -euo pipefail

      state_dir="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/weylus"
      output_file="$state_dir/headless-monitor"

      headless_outputs() {
        hyprctl monitors all -j \
          | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' \
          | sort
      }

      create() {
        mkdir -p "$state_dir"

        if [ -s "$output_file" ]; then
          output_name="$(cat "$output_file")"
          if hyprctl monitors all -j | jq -e --arg name "$output_name" '.[] | select(.name == $name)' >/dev/null; then
            exit 0
          fi
        fi

        before="$(mktemp)"
        after="$(mktemp)"
        trap 'rm -f "$before" "$after"' EXIT

        headless_outputs > "$before"
        hyprctl output create headless >/dev/null
        headless_outputs > "$after"

        output_name="$(comm -13 "$before" "$after" | head -n 1)"
        if [ -z "$output_name" ]; then
          output_name="$(head -n 1 "$after")"
        fi
        if [ -z "$output_name" ]; then
          printf 'Failed to detect created headless monitor\n' >&2
          exit 1
        fi

        hyprctl keyword monitor "$output_name,2360x1500@60,auto,1" >/dev/null
        printf '%s\n' "$output_name" > "$output_file"
      }

      remove() {
        if [ ! -s "$output_file" ]; then
          exit 0
        fi

        output_name="$(cat "$output_file")"
        rm -f "$output_file"

        if hyprctl monitors all -j | jq -e --arg name "$output_name" '.[] | select(.name == $name)' >/dev/null; then
          hyprctl output remove "$output_name" >/dev/null
        fi
      }

      case "''${1:-}" in
        create) create ;;
        remove) remove ;;
        *)
          printf 'Usage: %s create|remove\n' "$0" >&2
          exit 2
          ;;
      esac
    '';
  };

in
{
  systemd.user.services.weylus = {
    Unit = {
      Description = "Weylus tablet server";
      After = [ hyprlandSessionTarget ];
      PartOf = [ hyprlandSessionTarget ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      Type = "simple";
      ExecStartPre = "${weylusHeadlessMonitor}/bin/weylus-headless-monitor create";
      ExecStart = lib.escapeShellArgs [
        (lib.getExe weylus)
        "--no-gui"
        "--wayland-support"
      ];
      ExecStopPost = "${weylusHeadlessMonitor}/bin/weylus-headless-monitor remove";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}
