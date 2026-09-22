#!/usr/bin/env bash
set -u

# Adjust these to match the names shown by: playerctl -l
BROWSER_PLAYERS_REGEX='^(firefox|chromium|google-chrome|brave|vivaldi)'

# Polling avoids depending on playerctl/library event behavior.
INTERVAL=0.5

declare -A PAUSED_BY_SCRIPT=()
browser_was_playing=0

get_players() {
  playerctl -l 2>/dev/null || true
}

is_browser_player() {
  [[ "$1" =~ $BROWSER_PLAYERS_REGEX ]]
}

player_status() {
  playerctl --player="$1" status 2>/dev/null || true
}

pause_music_players() {
  local player status

  while IFS= read -r player; do
    [[ -z "$player" ]] && continue
    is_browser_player "$player" && continue

    status=$(player_status "$player")

    if [[ "$status" == "Playing" ]]; then
      playerctl --player="$player" pause 2>/dev/null || true
      PAUSED_BY_SCRIPT["$player"]=1
    fi
  done < <(get_players)
}

resume_music_players() {
  local player

  for player in "${!PAUSED_BY_SCRIPT[@]}"; do
    playerctl --player="$player" play 2>/dev/null || true
    unset 'PAUSED_BY_SCRIPT[$player]'
  done
}

while sleep "$INTERVAL"; do
  browser_is_playing=0

  while IFS= read -r player; do
    [[ -z "$player" ]] && continue

    if is_browser_player "$player" &&
      [[ "$(player_status "$player")" == "Playing" ]]; then
      browser_is_playing=1
      break
    fi
  done < <(get_players)

  if ((browser_is_playing && ! browser_was_playing)); then
    pause_music_players
  elif ((! browser_is_playing && browser_was_playing)); then
    resume_music_players
  fi

  browser_was_playing=$browser_is_playing
done
