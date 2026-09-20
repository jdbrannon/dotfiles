#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="${THEME_WALLPAPER_DIR:-/mnt/data/Nextcloud/01-Personal/08-Computer/03-Desktop-Backgrounds/Current_Desktop_Backgrounds}"

notify() {
  command -v notify-send >/dev/null && notify-send "Theme switcher" "$1"
}

if ! command -v awww >/dev/null || ! command -v awww-daemon >/dev/null; then
  notify "awww is required. Install it, then run this again."
  exit 1
fi

if ! command -v matugen >/dev/null || ! command -v rofi >/dev/null; then
  notify "matugen and rofi are required."
  exit 1
fi

shopt -s nullglob
wallpapers=("$wallpaper_dir"/*.{jpg,jpeg,png,webp,gif,JPG,JPEG,PNG,WEBP,GIF})
if ((${#wallpapers[@]} == 0)); then
  notify "No wallpapers found in $wallpaper_dir"
  exit 1
fi

selected=$(
  for wallpaper in "${wallpapers[@]}"; do
    name="$(basename "$wallpaper")"
    printf '%s\0icon\x1f%s\n' "$name" "$wallpaper"
  done | rofi -dmenu -i -show-icons -p "Theme"
) || exit 0
[[ -n "$selected" ]] || exit 0

wallpaper="$wallpaper_dir/$selected"
[[ -f "$wallpaper" ]] || exit 1

pgrep -x awww-daemon >/dev/null || awww-daemon &
awww img "$wallpaper" --transition-type grow --transition-duration 1
if ! matugen image "$wallpaper" --source-color-index 0; then
  notify "matugen failed to generate colors for $selected"
  exit 1
fi
ln -sfn "$wallpaper" "$HOME/.config/hypr/current_wallpaper"
hyprctl reload
notify "Applied theme: $selected"
