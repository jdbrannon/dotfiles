#!/usr/bin/env bash
# Opens a detailed forecast for the last-fetched location (falls back to an IP-based search).
loc=$(cat "${XDG_RUNTIME_DIR:-/tmp}/waybar-weather-loc" 2>/dev/null)
if [ -n "$loc" ]; then
  xdg-open "https://weather.com/weather/today/l/${loc}" >/dev/null 2>&1
else
  xdg-open "https://www.google.com/search?q=weather" >/dev/null 2>&1
fi
