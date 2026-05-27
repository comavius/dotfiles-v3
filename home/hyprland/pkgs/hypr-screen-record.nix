{
  coreutils,
  hyprland,
  jq,
  libnotify,
  slurp,
  systemd,
  writeShellApplication,
}:
writeShellApplication {
  name = "hypr-screen-record";
  runtimeInputs = [
    coreutils
    hyprland
    jq
    libnotify
    slurp
    systemd
  ];
  text = ''
    focused_output() {
      hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | select(.focused) | .name' \
        | head -n 1
    }

    unit="hypr-screen-record.service"
    record_dir="''${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
    state_dir="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/hypr-screen-record"
    mkdir -p "$record_dir"

    if systemctl --user is-active --quiet "$unit"; then
      systemctl --user stop "$unit"
      exit 0
    fi

    output="$record_dir/recording-$(date +%Y%m%d-%H%M%S).mkv"

    mkdir -p "$state_dir"
    if [ "''${1:-}" = "area" ]; then
      selection_with_output=$(slurp -o -f '%x,%y %wx%h %o') || exit 0
      selection="''${selection_with_output% *}"
      record_output="''${selection_with_output##* }"
      if [ "$record_output" = "<unknown>" ]; then
        record_output=""
      fi
      printf '%s\n' "$selection" > "$state_dir/geometry"
    else
      record_output=$(focused_output || true)
      : > "$state_dir/geometry"
    fi
    printf '%s\n' "$record_output" > "$state_dir/output-name"
    printf '%s\n' "$output" > "$state_dir/output"

    systemctl --user reset-failed "$unit" >/dev/null 2>&1 || true
    systemctl --user start "$unit"
  '';
}
