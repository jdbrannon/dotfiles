#!/usr/bin/env bash

set -u

library="/mnt/data/SteamLibrary"
manifest_dir="$library/steamapps"

desktop_dir="$HOME/.local/share/applications"
icon_dir="$HOME/.local/share/icons/steam"
sgdb_key_file="$HOME/.config/hypr/scripts/.steamgriddb_api_key"

mkdir -p "$desktop_dir" "$icon_dir"

sgdb_key=""
if [[ -s "$sgdb_key_file" ]]; then
  sgdb_key=$(<"$sgdb_key_file")
fi

# Looks up the Steam appid on SteamGridDB and downloads its top-scored
# "official" icon (falls back to top-scored icon of any style). Returns
# non-zero if no key is configured or nothing usable was found.
fetch_steamgriddb_icon() {
  local appid="$1" dest="$2"
  [[ -n "$sgdb_key" ]] && command -v jq >/dev/null || return 1

  local sgdb_id
  sgdb_id=$(curl -fsS -H "Authorization: Bearer $sgdb_key" \
    "https://www.steamgriddb.com/api/v2/games/steam/$appid" 2>/dev/null |
    jq -r 'if .success then (.data.id // empty) else empty end') || return 1
  [[ -n "$sgdb_id" ]] || return 1

  local icon_url
  icon_url=$(curl -fsS -H "Authorization: Bearer $sgdb_key" \
    "https://www.steamgriddb.com/api/v2/icons/game/$sgdb_id" 2>/dev/null |
    jq -r '
      if .success and (.data | length) > 0 then
        (.data
          | sort_by(-.score, -(.width * .height))
          | sort_by(if .style == "official" then 0 else 1 end)
          | .[0].url)
      else empty end
    ') || return 1
  [[ -n "$icon_url" && "$icon_url" != "null" ]] || return 1

  curl -fL --retry 2 -sS -o "$dest" "$icon_url"
}

if [[ ! -d "$manifest_dir" ]]; then
  echo "Steam manifest directory not found:"
  echo "  $manifest_dir"
  exit 1
fi

for manifest in "$manifest_dir"/appmanifest_*.acf; do
  [[ -f "$manifest" ]] || continue

  appid=$(basename "$manifest" | sed -E 's/appmanifest_([0-9]+)\.acf/\1/')
  name=$(sed -n 's/^[[:space:]]*"name"[[:space:]]*"\(.*\)"$/\1/p' "$manifest" | head -n 1)

  [[ -n "$appid" && -n "$name" ]] || continue

  # Steam auto-generates its own launcher + icon once it has indexed the game;
  # skip those to avoid duplicate rofi entries, and drop any stale one of ours.
  if grep -l "rungameid/$appid\"\?$" "$desktop_dir"/*.desktop 2>/dev/null |
    grep -qv "^$desktop_dir/steam-$appid\.desktop$"; then
    if [[ -f "$desktop_dir/steam-$appid.desktop" ]]; then
      rm -f "$desktop_dir/steam-$appid.desktop"
      echo "Skipping $name (already provided by Steam), removed stale entry"
    else
      echo "Skipping $name (already provided by Steam)"
    fi
    continue
  fi

  icon="$icon_dir/$appid.jpg"
  librarycache="$HOME/.local/share/Steam/appcache/librarycache/$appid"

  # Prefer the icon Steam itself already extracted into the icon theme (matches
  # the game's real logo) over the CDN header/capsule art.
  themed_icon=""
  for size in 256x256 128x128 96x96 64x64 48x48 32x32; do
    candidate="$HOME/.local/share/icons/hicolor/$size/apps/steam_icon_$appid.png"
    if [[ -s "$candidate" ]]; then
      themed_icon="steam_icon_$appid"
      break
    fi
  done

  if [[ -n "$themed_icon" ]]; then
    icon="$themed_icon"
  elif [[ ! -s "$icon" ]]; then
    if fetch_steamgriddb_icon "$appid" "$icon"; then
      : # got a high-res official icon from SteamGridDB
    else
      # Next best: the small square icon Steam already downloaded locally for
      # its library UI (a hash-named .jpg sitting directly in the app's
      # librarycache dir, as opposed to the "library_*"/"logo.png" art assets).
      cache_icon=$(find "$librarycache" -maxdepth 1 -type f -iname '*.jpg' \
        ! -iname 'library_*' 2>/dev/null | head -n 1)

      if [[ -n "$cache_icon" ]]; then
        cp -f "$cache_icon" "$icon"
      else
        echo "Downloading artwork for $name..."

        downloaded=0

        for url in \
          "https://cdn.cloudflare.steamstatic.com/steam/apps/$appid/header.jpg" \
          "https://cdn.cloudflare.steamstatic.com/steam/apps/$appid/capsule_231x87.jpg" \
          "https://cdn.cloudflare.steamstatic.com/steam/apps/$appid/capsule_184x69.jpg"; do
          if curl -fL --retry 2 -sS -o "$icon" "$url"; then
            downloaded=1
            break
          fi
        done

        if [[ "$downloaded" -eq 0 ]]; then
          rm -f "$icon"
          icon="steam"
        fi
      fi
    fi
  fi

  safe_name=$(printf '%s' "$name" |
    sed 's/[\\]/\\\\/g; s/[;]/\\;/g')

  cat >"$desktop_dir/steam-$appid.desktop" <<EOF
[Desktop Entry]
Name=$safe_name
Comment=Launch $safe_name through Steam
Exec=steam steam://rungameid/$appid
Icon=$icon
Terminal=false
Type=Application
Categories=Game;
EOF

  echo "Created launcher: $name"
done

update-desktop-database "$desktop_dir" 2>/dev/null || true
