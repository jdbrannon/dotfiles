#!/usr/bin/env bash
# Shared helper sourced by the media-* waybar scripts. Maintains a single
# background `playerctl --follow status` writer (guarded by flock) so
# multiple modules/processes can all cheaply read the same status file
# instead of each polling playerctl on its own.

MEDIA_STATUS_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-media-status"
MEDIA_STATUS_LOCK="${MEDIA_STATUS_FILE}.lock"

# Starts the background writer if no other instance already holds the lock.
# Safe to call from every consumer script; only one writer ever runs.
ensure_media_status_watcher() {
  [ -f "$MEDIA_STATUS_FILE" ] || echo "Paused" >"$MEDIA_STATUS_FILE"

  (
    flock -n 9 || exit 0
    playerctl -p playerctld --follow status 2>/dev/null | while read -r s; do
      echo "$s" >"$MEDIA_STATUS_FILE"
    done
  ) 9>"$MEDIA_STATUS_LOCK" &
  disown
}

media_status() {
  cat "$MEDIA_STATUS_FILE" 2>/dev/null
}
