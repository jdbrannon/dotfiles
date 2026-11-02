#!/usr/bin/env bash
set -u

# Long-running: prints a JSON line per update. While offline it retries with
# exponential backoff (RETRY_MIN..RETRY_MAX), refreshes every 30 min once
# successful, and refreshes immediately on SIGUSR1 or when NetworkManager
# reports a new connection.
REFRESH=1800
RETRY_MIN=10
RETRY_MAX=600

# WMO weather codes (https://open-meteo.com/en/docs)
wmo_icon() {
  case "$1" in
  0) echo "☀️" ;;
  1 | 2) echo "🌤️" ;;
  3) echo "☁️" ;;
  45 | 48) echo "🌫️" ;;
  51 | 53 | 55 | 56 | 57) echo "🌦️" ;;
  61 | 63 | 65 | 66 | 67) echo "🌧️" ;;
  71 | 73 | 75 | 77) echo "❄️" ;;
  80 | 81 | 82) echo "🌧️" ;;
  85 | 86) echo "🌨️" ;;
  95 | 96 | 99) echo "⛈️" ;;
  *) echo "" ;;
  esac
}

wmo_desc() {
  case "$1" in
  0) echo "Clear sky" ;;
  1) echo "Mainly clear" ;;
  2) echo "Partly cloudy" ;;
  3) echo "Overcast" ;;
  45 | 48) echo "Fog" ;;
  51 | 53 | 55) echo "Drizzle" ;;
  56 | 57) echo "Freezing drizzle" ;;
  61 | 63 | 65) echo "Rain" ;;
  66 | 67) echo "Freezing rain" ;;
  71 | 73 | 75) echo "Snow" ;;
  77) echo "Snow grains" ;;
  80 | 81 | 82) echo "Rain showers" ;;
  85 | 86) echo "Snow showers" ;;
  95) echo "Thunderstorm" ;;
  96 | 99) echo "Thunderstorm, hail" ;;
  *) echo "Unknown" ;;
  esac
}

# Nerd Font "weather-windy" glyph in light blue
wind_icon="<span foreground='#8ecbff'>󰖝</span>"

fetch() {
  loc_response=$(curl -s --max-time 5 https://ipinfo.io/loc) || return 1
  latitude=$(echo "$loc_response" | cut -d',' -f1)
  longitude=$(echo "$loc_response" | cut -d',' -f2)
  [ -n "$latitude" ] && [ -n "$longitude" ] || return 1
  echo "${latitude},${longitude}" >"${XDG_RUNTIME_DIR:-/tmp}/waybar-weather-loc"

  weather_result=$(curl -s --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&wind_speed_unit=mph&temperature_unit=fahrenheit&timezone=auto&forecast_days=7") || return 1

  temp=$(echo "$weather_result" | jq -r '.current.temperature_2m // empty')
  code=$(echo "$weather_result" | jq -r '.current.weather_code // empty')
  [ -n "$temp" ] && [ -n "$code" ] || return 1

  temp_rounded=$(printf '%.0f' "$temp")
  icon=$(wmo_icon "$code")

  tooltip="<b>${icon} $(wmo_desc "$code")</b>"$'\n\n'"<b>Next 12 hours</b>"
  row_time="" row_icon="" row_temp="" row_rain=""
  while IFS=$'\t' read -r label t c p; do
    row_time+=$(printf '%-5s' "$label")
    row_icon+="$(wmo_icon "$c")   "
    n=$(printf '%.0f' "$t")
    row_temp+="${n}°$(printf '%*s' $((4 - ${#n})) '')"
    row_rain+=$(printf '%-5s' "${p}%")
  done < <(echo "$weather_result" | jq -r '
    .current.time as $now
    | [.hourly.time, .hourly.temperature_2m, .hourly.weather_code, .hourly.precipitation_probability]
    | transpose
    | map(select(.[0] > $now))
    | .[0:12] as $h
    | $h[]
    | [(.[0] | split("T")[1] | split(":")[0] | tonumber | if . == 0 then "12a" elif . < 12 then "\(.)a" elif . == 12 then "12p" else "\(. - 12)p" end),
       .[1], .[2], (.[3] // 0)]
    | @tsv')
  tooltip+=$'\n'"$row_time"$'\n'"$row_icon"$'\n'"$row_rain"$'\n'"$row_temp"

  tooltip+=$'\n\n'"<b>7-day forecast</b>"
  while IFS=$'\t' read -r label hi lo c p w bar; do
    tooltip+=$'\n'"$(printf '%-10s   %s %3s° %s %3s°  💧%3s%%  %s%2s mph' "$label" "$(wmo_icon "$c")" "$lo" "$bar" "$hi" "$p" "$wind_icon" "$w")"
  done < <(echo "$weather_result" | jq -r '
    [.daily.time, .daily.temperature_2m_max, .daily.temperature_2m_min, .daily.weather_code, .daily.precipitation_probability_max, .daily.wind_speed_10m_max]
    | transpose as $d
    | ($d | map(.[2]) | min) as $lo
    | ($d | map(.[1]) | max) as $hi
    | 14 as $w
    | $d[]
    | (if $hi == $lo then 0 else (.[2] - $lo) / ($hi - $lo) * ($w - 1) | round end) as $s
    | (if $hi == $lo then ($w - 1) else (.[1] - $lo) / ($hi - $lo) * ($w - 1) | round end) as $e
    | [(.[0] | strptime("%Y-%m-%d") | mktime | strftime("%a %b %e")),
       (.[1] | round), (.[2] | round), .[3], (.[4] // 0), (.[5] // 0 | round),
       ([range(0; $w)] | map(if . >= $s and . <= $e then "━" else " " end) | join(""))]
    | @tsv')

  jq -cn --arg text "$icon ${temp_rounded}°F" --arg tooltip "<tt>${tooltip}</tt>" '{text: $text, tooltip: $tooltip}'
}

nap() {
  sleep "$1" &
  wait $!
}

trap ':' USR1

if command -v nmcli >/dev/null; then
  while read -r line; do
    case "$line" in *"connected"*) [[ "$line" == *disconnected* ]] || kill -USR1 $$ 2>/dev/null ;; esac
  done < <(nmcli monitor 2>/dev/null) &
  monitor_pid=$!
  trap 'kill "$monitor_pid" 2>/dev/null' EXIT
fi

delay=$RETRY_MIN

have_data=0
while true; do
  if out=$(fetch); then
    echo "$out"
    have_data=1
    delay=$RETRY_MIN
    nap "$REFRESH"
  else
    [ "$have_data" = 1 ] || printf '{"text":"?","tooltip":"Weather unavailable (retrying; click to refresh)"}\n'
    nap "$delay"
    delay=$((delay * 2 > RETRY_MAX ? RETRY_MAX : delay * 2))
  fi
done
