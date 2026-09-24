#!/usr/bin/env bash
set -u

if ! pgrep -x spotify >/dev/null; then
  spicetify --no-restart refresh
  spotify --remote-debugging-port=9222 --remote-allow-origins='*' "$@" &
else
  spotify "$@" &
fi

for _ in {1..100}; do
  if curl -fsS http://127.0.0.1:9222/json/list >/dev/null; then
    systemctl --user restart spicetify-watch.service
    exit 0
  fi
  sleep 0.1
done

notify-send "Spotify theme watcher" "Spotify was not launched with live theme support."
exit 1