#!/usr/bin/env bash
# Idempotent per-machine setup, run from hyprland.lua at startup.
# Every step is a no-op once done, or skipped until its prerequisite exists
# (e.g. the Nextcloud account added in gnome-online-accounts-gtk).
set -u

have() { command -v "$1" >/dev/null 2>&1; }

# Calendar sync timer (the "enabled" symlink isn't carried by dotfiles)
if have vdirsyncer && ! systemctl --user is-enabled --quiet vdirsyncer.timer 2>/dev/null; then
  systemctl --user daemon-reload
  systemctl --user enable --now vdirsyncer.timer
fi

# First-time vdirsyncer discovery + sync, once the keyring has the password
if have vdirsyncer && have secret-tool &&
  secret-tool lookup service vdirsyncer-nextcloud username jdbrannon >/dev/null 2>&1 &&
  ! compgen -G "$HOME/.local/share/khal/calendars/*/" >/dev/null; then
  vdirsyncer discover nextcloud_calendars </dev/null && vdirsyncer sync
fi

# Default calendar for GNOME Calendar: Nextcloud "Personal", unless already changed
if have gsettings &&
  [ "$(gsettings get org.gnome.Evolution.DefaultSources default-calendar 2>/dev/null)" = "'system'" ]; then
  for f in "$HOME"/.cache/evolution/sources/*/*.source; do
    [ -f "$f" ] || continue
    if grep -q '^\[Calendar\]' "$f" && grep -q '^DisplayName=Personal$' "$f"; then
      gsettings set org.gnome.Evolution.DefaultSources default-calendar "$(basename "$f" .source)"
      break
    fi
  done
fi
