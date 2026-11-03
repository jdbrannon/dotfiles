#!/usr/bin/env bash

source "$(dirname "$0")/media-status.sh"
ensure_media_status_watcher

play_icon=""
pause_icon=""

# emit once immediately, then react to status changes as they happen
tail -n1 -F "$MEDIA_STATUS_FILE" 2>/dev/null | while read -r status; do
  if [ "$status" = "Playing" ]; then
    echo "$pause_icon"
  elif [ "$status" = "Paused" ]; then
    echo "$play_icon"
  else
    echo ""
  fi
done
