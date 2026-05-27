{
  coreutils,
  libnotify,
  wf-recorder,
  xdg-utils,
  writeShellApplication,
}:
writeShellApplication {
  name = "hypr-screen-record-service";
  runtimeInputs = [
    coreutils
    libnotify
    wf-recorder
    xdg-utils
  ];
  text = ''
    notify_saved() {
      title="$1"
      path="$2"

      (
        action=$(notify-send --action=default="Open" "$title" "$path" || true)
        if [ "$action" = "default" ]; then
          xdg-open "$path" >/dev/null 2>&1 &
        fi
      ) >/dev/null 2>&1 &
    }

    state_dir="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/hypr-screen-record"
    geometry_file="$state_dir/geometry"
    output_name_file="$state_dir/output-name"
    output_file="$state_dir/output"

    if [ ! -e "$geometry_file" ] || [ ! -s "$output_file" ]; then
      notify-send "Screen recording failed" "Missing recording state"
      exit 1
    fi

    geometry=$(cat "$geometry_file")
    record_output=""
    if [ -e "$output_name_file" ]; then
      record_output=$(cat "$output_name_file")
    fi
    output=$(cat "$output_file")
    recorder_pid=""

    # shellcheck disable=SC2329
    stop_recording() {
      trap - INT TERM
      if [ -n "$recorder_pid" ] && kill -0 "$recorder_pid" 2>/dev/null; then
        kill -INT "$recorder_pid" 2>/dev/null || true
        wait "$recorder_pid" 2>/dev/null || true
      fi
      notify_saved "Screen recording stopped" "$output"
      exit 0
    }

    notify-send "Screen recording started"
    recorder_args=(-f "$output")
    if [ -n "$geometry" ]; then
      recorder_args=(-g "$geometry" "''${recorder_args[@]}")
    fi
    if [ -n "$record_output" ]; then
      recorder_args=(-o "$record_output" "''${recorder_args[@]}")
    fi
    wf-recorder "''${recorder_args[@]}" &
    recorder_pid="$!"

    trap stop_recording INT TERM
    set +e
    wait "$recorder_pid"
    status="$?"
    set -e

    notify_saved "Screen recording stopped" "$output"
    exit "$status"
  '';
}
