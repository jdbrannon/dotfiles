#!/usr/bin/env bash
# Prints waybar JSON: time as text, full date as the tooltip. The calendar lives in calendar-popup.py.
jq -cn --arg text "$(date '+%I:%M %p')" --arg tooltip "$(date '+%b %-d, %Y (%A)')" '{text: $text, tooltip: $tooltip}'
