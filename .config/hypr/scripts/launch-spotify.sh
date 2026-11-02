#!/usr/bin/env bash
set -u

if ! pgrep -x spotify >/dev/null; then
  # Re-patch after a Spotify update (or on a fresh machine), otherwise just refresh
  spotify_version=$(/opt/spotify/spotify --version 2>/dev/null | sed -n 's/^Spotify version \([^,]*\),.*/\1/p')
  backup_version=$(sed -n 's/^version *= *//p' "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null)
  if [ -n "$spotify_version" ] && [ "$spotify_version" != "$backup_version" ]; then
    spicetify --no-restart backup apply
  else
    spicetify --no-restart refresh
  fi
  spotify --remote-debugging-port=9222 --remote-allow-origins='*' "$@" &
else
  spotify "$@" &
fi

for _ in {1..100}; do
  if curl -fsS http://127.0.0.1:9222/json/list >/dev/null; then
    pidfile="${XDG_RUNTIME_DIR:-/tmp}/spicetify-watch.pid"
    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
      kill "$(cat "$pidfile")"
    fi
    spicetify -s watch >/dev/null 2>&1 &
    echo $! >"$pidfile"
    disown
    exit 0
  fi
  sleep 0.1
done

notify-send "Spotify theme watcher" "Spotify was not launched with live theme support."
exit 1