{
  coreutils,
  gawk,
  libnotify,
  pulseaudio,
  pavucontrol,
  systemd,
  wofi,
  writeShellApplication,
}:
writeShellApplication {
  name = "waybar-audio-control";
  runtimeInputs = [
    coreutils
    gawk
    libnotify
    pulseaudio
    pavucontrol
    systemd
    wofi
  ];
  text = ''
    set -euo pipefail

    notify_audio() {
      notify-send --app-name=waybar "Audio" "$1"
    }

    current_sink() {
      pactl get-default-sink 2>/dev/null || true
    }

    sink_description() {
      local wanted="$1"
      pactl list sinks | awk -v wanted="$wanted" '
        /^Sink #[0-9]+/ {
          if (name == wanted) {
            print description
            exit
          }
          name = ""
          description = ""
          next
        }
        /^\tName: / {
          name = substr($0, 8)
          next
        }
        /^\tDescription: / {
          description = substr($0, 15)
          next
        }
        END {
          if (name == wanted) {
            print description
          }
        }
      '
    }

    list_sinks() {
      local current="$1"
      pactl list sinks | awk -v current="$current" '
        function emit() {
          if (name == "") {
            return
          }
          marker = name == current ? "*" : " "
          printf "%s %s (%s)\t%s\n", marker, description, state, name
        }
        /^Sink #[0-9]+/ {
          emit()
          name = ""
          description = ""
          state = "unknown"
          next
        }
        /^\tName: / {
          name = substr($0, 8)
          next
        }
        /^\tDescription: / {
          description = substr($0, 15)
          next
        }
        /^\tState: / {
          state = substr($0, 9)
          next
        }
        END {
          emit()
        }
      '
    }

    list_ports() {
      local wanted="$1"
      pactl list sinks | awk -v wanted="$wanted" '
        function reset_sink() {
          name = ""
          active = ""
          in_sink = 0
          in_ports = 0
        }
        BEGIN {
          reset_sink()
        }
        /^Sink #[0-9]+/ {
          reset_sink()
          next
        }
        /^\tName: / {
          name = substr($0, 8)
          in_sink = name == wanted
          next
        }
        in_sink && /^\tActive Port: / {
          active = substr($0, 15)
          next
        }
        in_sink && /^\tPorts:/ {
          in_ports = 1
          next
        }
        in_sink && in_ports && /^\t\t[^:]+: / {
          line = $0
          sub(/^\t\t/, "", line)
          separator = index(line, ": ")
          port = substr(line, 1, separator - 1)
          description = substr(line, separator + 2)
          sub(/ \(.*$/, "", description)
          marker = port == active ? "*" : " "
          printf "%s %s\t%s\n", marker, description, port
          next
        }
        in_sink && in_ports && /^\t[^\t]/ {
          in_ports = 0
        }
      '
    }

    move_playing_streams() {
      local sink="$1"
      pactl list short sink-inputs | awk '{ print $1 }' | while read -r input_id; do
        if [ -n "$input_id" ]; then
          pactl move-sink-input "$input_id" "$sink" || true
        fi
      done
    }

    choose_from_menu() {
      wofi --show dmenu --prompt "$1"
    }

    select_sink() {
      local current choice sink description
      current="$(current_sink)"
      choice="$(
        {
          printf "Select port for current output\t__ports__\n"
          printf "Open volume mixer\t__mixer__\n"
          printf "Restart PipeWire audio\t__restart__\n"
          list_sinks "$current"
        } | choose_from_menu "Audio"
      )"

      [ -n "$choice" ] || exit 0
      sink="$(printf '%s\n' "$choice" | awk -F '\t' '{ print $2 }')"

      case "$sink" in
        __ports__)
          select_port
          ;;
        __mixer__)
          pavucontrol &
          ;;
        __restart__)
          restart_audio
          ;;
        "")
          exit 0
          ;;
        *)
          pactl set-default-sink "$sink"
          move_playing_streams "$sink"
          description="$(sink_description "$sink")"
          notify_audio "Output switched to ''${description:-$sink}"
          ;;
      esac
    }

    select_port() {
      local sink choice port description
      sink="$(current_sink)"
      if [ -z "$sink" ]; then
        notify_audio "No default output sink found"
        exit 1
      fi

      choice="$(list_ports "$sink" | choose_from_menu "Output port")"
      [ -n "$choice" ] || exit 0
      port="$(printf '%s\n' "$choice" | awk -F '\t' '{ print $2 }')"
      [ -n "$port" ] || exit 0

      pactl set-sink-port "$sink" "$port"
      description="$(sink_description "$sink")"
      notify_audio "Port switched on ''${description:-$sink}"
    }

    restart_audio() {
      systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
      notify_audio "PipeWire audio restarted"
    }

    case "''${1:-menu}" in
      menu)
        select_sink
        ;;
      port)
        select_port
        ;;
      restart)
        restart_audio
        ;;
      *)
        printf 'usage: waybar-audio-control [menu|port|restart]\n' >&2
        exit 2
        ;;
    esac
  '';
}
