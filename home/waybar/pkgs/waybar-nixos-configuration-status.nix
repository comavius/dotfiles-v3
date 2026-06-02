{
  coreutils,
  git,
  jq,
  lib,
  writeShellApplication,
  dotfilesRepositoryPath,
}:
writeShellApplication {
  name = "waybar-nixos-configuration-status";
  runtimeInputs = [
    coreutils
    git
    jq
  ];
  text = ''
    repo=${lib.escapeShellArg dotfilesRepositoryPath}

    emit() {
      jq -cn \
        --arg text "$1" \
        --arg class "$2" \
        --arg tooltip "$3" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    }

    revision="$(
      /run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null || true
    )"

    if [ -z "$revision" ] || [ "$revision" = "null" ]; then
      emit "?" "unknown" "Configuration revision is not available"
      exit 0
    fi

    comparison_revision="''${revision%-dirty}"
    short_revision="''${comparison_revision:0:8}"
    dirty_tooltip=""

    if [ "$revision" != "$comparison_revision" ]; then
      dirty_tooltip="$(printf '\nDirty tree: yes')"
    fi

    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      tooltip="$(printf 'Active NixOS: %s\nRepository not found: %s%s' "$short_revision" "$repo" "$dirty_tooltip")"
      emit "?" "unknown" "$tooltip"
      exit 0
    fi

    if ! git -C "$repo" rev-parse --verify --quiet origin/main >/dev/null; then
      tooltip="$(printf 'Active NixOS: %s\nRepository: %s\norigin/main is not available%s' "$short_revision" "$repo" "$dirty_tooltip")"
      emit "?" "unknown" "$tooltip"
      exit 0
    fi

    origin_revision="$(git -C "$repo" rev-parse --short=8 origin/main)"
    fetch_head="$(git -C "$repo" rev-parse --absolute-git-dir)/FETCH_HEAD"
    origin_last_updated="unknown"

    if [ -e "$fetch_head" ]; then
      origin_last_updated="$(date -d "@$(stat -c %Y "$fetch_head")" "+%Y-%m-%d %H:%M:%S %z")"
    fi

    if ! git -C "$repo" cat-file -e "$comparison_revision^{commit}" >/dev/null 2>&1; then
      tooltip="$(printf 'Active NixOS: %s\norigin/main: %s\norigin/main last updated: %s\nRepository: %s\nConfiguration commit is not present in this worktree%s' "$short_revision" "$origin_revision" "$origin_last_updated" "$repo" "$dirty_tooltip")"
      emit "?" "unknown" "$tooltip"
      exit 0
    fi

    counts="$(
      git -C "$repo" rev-list --left-right --count "$comparison_revision...origin/main" 2>/dev/null || true
    )"

    if [ -z "$counts" ]; then
      tooltip="$(printf 'Active NixOS: %s\norigin/main: %s\norigin/main last updated: %s\nRepository: %s\nCould not compare with origin/main%s' "$short_revision" "$origin_revision" "$origin_last_updated" "$repo" "$dirty_tooltip")"
      emit "?" "unknown" "$tooltip"
      exit 0
    fi

    read -r ahead behind <<< "$counts"

    status="current"

    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
      status="diverged"
    elif [ "$ahead" -gt 0 ]; then
      status="ahead"
    elif [ "$behind" -gt 0 ]; then
      status="behind"
    fi

    tooltip="$(printf 'Active NixOS: %s\norigin/main: %s\norigin/main last updated: %s\nAhead of origin/main: %s\nBehind origin/main: %s\nRepository: %s%s' "$short_revision" "$origin_revision" "$origin_last_updated" "$ahead" "$behind" "$repo" "$dirty_tooltip")"
    emit "⇡$ahead ⇣$behind" "$status" "$tooltip"
  '';
}
