#!/usr/bin/env bash

killall -9 waybar
killall -9 swaync
# waybar's script children survive killall; clear the media helper so it is not duplicated
pkill -f "scripts/media.py"; killall cava 2>/dev/null
waybar -c ~/.config/waybar/configs/default.jsonc &
swaync &
