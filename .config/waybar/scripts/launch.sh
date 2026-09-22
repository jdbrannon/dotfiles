#!/usr/bin/env bash

killall -9 waybar
killall -9 swaync
waybar -c ~/.config/waybar/configs/default.jsonc &
swaync &
