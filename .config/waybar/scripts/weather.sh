#!/bin/bash

loc_response=$(curl -s https://ipinfo.io/loc)
latitude=$(echo "$loc_response" | cut -d',' -f1)
longitude=$(echo "$loc_response" | cut -d',' -f2)

weather_result = $(curl -s "https://api.open-meteo.com/v1/forecast?latitude=latitude&longitude=$longitude&hourly=temperature_2m,weather_code&models=ncep_gfs_seamless&forecast_days=7&temperature_unit=fahrenheit")

case $ICON_CODE in
"01d") ICON="☀️" ;;         # Clear sky day
"01n") ICON="🌙" ;;          # Clear sky night
"02d") ICON="⛅" ;;          # Few clouds day
"02n") ICON="☁️" ;;         # Few clouds night
"03d" | "03n") ICON="☁️" ;; # Scattered clouds
"04d" | "04n") ICON="☁️" ;; # Broken clouds
"09d" | "09n") ICON="🌧️" ;; # Shower rain
"10d") ICON="🌦️" ;;         # Rain day
"10n") ICON="🌧️" ;;         # Rain night
"11d" | "11n") ICON="⛈️" ;; # Thunderstorm
"13d" | "13n") ICON="❄️" ;; # Snow
"50d" | "50n") ICON="🌫️" ;; # Mist
*) ICON="❓" ;;              # Default
esac

# Determine unit label
if [ "$UNITS" = "metric" ]; then
  LABEL="°C"
else
  LABEL="°F"
fi
