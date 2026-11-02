#!/usr/bin/env bash
# Prints waybar JSON: time as text, tooltip = month calendar + upcoming khal events.
text=$(date '+%I:%M %p | %a %e')

today=$(date +%e | tr -d ' ')
month=$(cal | sed -e 's/&/\&amp;/g' | sed -E "s/(^| )($today)( |\$)/\1<b><span foreground='#8ecbff'>\2<\/span><\/b>\3/")
# uid -> event COLOR (iCalendar property), read from the synced .ics files
declare -A colors
while IFS=$'\t' read -r uid color; do
  colors[$uid]=$color
done < <(awk -F: '
  FNR == 1 { uid = ""; color = "" }
  /^UID:/ { uid = substr($0, 5); sub(/\r$/, "", uid) }
  /^COLOR:/ { color = substr($0, 7); sub(/\r$/, "", color) }
  /^END:VEVENT/ { if (uid != "" && color != "") print uid "\t" color; uid = ""; color = "" }
' ~/.local/share/khal/calendars/*/*.ics 2>/dev/null)

esc() { sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<<"$1"; }

events=""
while IFS= read -r line; do
  if [[ "$line" == DAY:* ]]; then
    events+="<b>$(esc "${line#DAY:}")</b>"$'\n'
    continue
  fi
  uid=${line%%|*}
  rest=${line#*|}
  color=${colors[$uid]:-}
  if [ -n "$color" ] && [[ "$color" =~ ^[A-Za-z0-9#]+$ ]]; then
    dot="<span foreground='$color'>●</span>"
  else
    dot="<span foreground='#888888'>●</span>"
  fi
  events+="$dot $(esc "$rest")"$'\n'
done < <(khal list now 7d --day-format 'DAY:{name}, {date}' --format '{uid}|{start-end-time-style} {title}' 2>/dev/null)
events=${events%$'\n'}
[ -n "$events" ] || events="No events in the next 7 days"

tooltip="<tt>${month}</tt>"$'\n\n'"<b>Upcoming</b>"$'\n'"${events}"
jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip}'
