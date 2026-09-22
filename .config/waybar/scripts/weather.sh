#!/usr/bin/env bash
set -u

fallback() {
  printf '{"text":"?","tooltip":"Weather unavailable"}\n'
  exit 0
}

loc_response=$(curl -s --max-time 5 https://ipinfo.io/loc) || fallback
latitude=$(echo "$loc_response" | cut -d',' -f1)
longitude=$(echo "$loc_response" | cut -d',' -f2)
[ -n "$latitude" ] && [ -n "$longitude" ] || fallback

weather_result=$(curl -s --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,weather_code&temperature_unit=fahrenheit") || fallback

temp=$(echo "$weather_result" | jq -r '.current.temperature_2m // empty')
code=$(echo "$weather_result" | jq -r '.current.weather_code // empty')
[ -n "$temp" ] && [ -n "$code" ] || fallback

# WMO weather codes (https://open-meteo.com/en/docs)
case "$code" in
0) icon="☀️" ;;                        # Clear sky
1 | 2) icon="🌤️" ;;                    # Mainly clear / partly cloudy
3) icon="☁️" ;;                        # Overcast
45 | 48) icon="🌫️" ;;                  # Fog
51 | 53 | 55 | 56 | 57) icon="🌦️" ;;   # Drizzle
61 | 63 | 65 | 66 | 67) icon="🌧️" ;;   # Rain
71 | 73 | 75 | 77) icon="❄️" ;;        # Snow
80 | 81 | 82) icon="🌧️" ;;             # Rain showers
85 | 86) icon="🌨️" ;;                  # Snow showers
95 | 96 | 99) icon="⛈️" ;;             # Thunderstorm
*) icon="❓" ;;
esac

temp_rounded=$(printf '%.0f' "$temp")
printf '{"text":"%s %s°F","tooltip":"Weather: %s°F"}\n' "$icon" "$temp_rounded" "$temp_rounded"

