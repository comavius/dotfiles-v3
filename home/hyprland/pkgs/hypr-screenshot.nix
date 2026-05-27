{
  coreutils,
  grim,
  libnotify,
  slurp,
  xdg-utils,
  writeShellApplication,
}:
writeShellApplication {
  name = "hypr-screenshot";
  runtimeInputs = [
    coreutils
    grim
    libnotify
    slurp
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

    screenshot_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
    mkdir -p "$screenshot_dir"

    output="$screenshot_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

    if [ "''${1:-}" = "area" ]; then
      selection=$(slurp -o -f '%x,%y %wx%h') || exit 0
      grim -g "$selection" "$output"
    else
      grim "$output"
    fi

    notify_saved "Screenshot saved" "$output"
  '';
}
