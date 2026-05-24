{
  coreutils,
  libnotify,
  slurp,
  systemd,
  writeShellApplication,
}:
writeShellApplication {
  name = "hypr-screen-record";
  runtimeInputs = [
    coreutils
    libnotify
    slurp
    systemd
  ];
  text = ''
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
      selection=$(slurp) || exit 0
      printf '%s\n' "$selection" > "$state_dir/geometry"
    else
      : > "$state_dir/geometry"
    fi
    printf '%s\n' "$output" > "$state_dir/output"

    systemctl --user reset-failed "$unit" >/dev/null 2>&1 || true
    systemctl --user start "$unit"
  '';
}
