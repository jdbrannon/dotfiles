#!/usr/bin/env bash
# Toggles the calendar popup (closes it if already open).
if pid=$(pgrep -f 'scripts/calendar-popup.py'); then
  kill $pid
else
  LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so exec python3 ~/.config/waybar/scripts/calendar-popup.py
fi
