{
  jq,
  libnotify,
  systemd,
  writeShellApplication,
}:
writeShellApplication {
  name = "waybar-weylus-control";
  runtimeInputs = [
    jq
    libnotify
    systemd
  ];
  text = ''
    set -euo pipefail

    unit="weylus.service"
    icon="󰓶"

    emit() {
      jq -cn \
        --arg text "$1" \
        --arg class "$2" \
        --arg tooltip "$3" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    }

    status() {
      if systemctl --user is-active --quiet "$unit"; then
        emit "$icon" "running" "$(printf 'Weylus is running\nhttp://localhost:1701\nLeft click: stop')"
      elif systemctl --user is-failed --quiet "$unit"; then
        emit "$icon" "failed" "$(printf 'Weylus failed\nLeft click: restart')"
      else
        emit "$icon" "stopped" "$(printf 'Weylus is stopped\nLeft click: start')"
      fi
    }

    toggle() {
      if systemctl --user is-active --quiet "$unit"; then
        systemctl --user stop "$unit"
        notify-send --app-name=waybar "Weylus" "Stopped"
      else
        systemctl --user reset-failed "$unit" >/dev/null 2>&1 || true
        systemctl --user start "$unit"
        notify-send --app-name=waybar "Weylus" "Started on http://localhost:1701"
      fi
    }

    case "''${1:-status}" in
      status) status ;;
      toggle) toggle ;;
      *)
        printf 'Usage: %s [status|toggle]\n' "$0" >&2
        exit 2
        ;;
    esac
  '';
}
