#!/usr/bin/env bash
# Closes pwvucontrol if it is currently focused.
# Bound to Escape as a non-consuming keybind, so this never affects other apps.
set -euo pipefail

class="$(hyprctl activewindow -j 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("class",""))' 2>/dev/null || true)"

case "$class" in
  com.saivert.pwvucontrol)
    hyprctl dispatch 'hl.dsp.window.close()' >/dev/null
    ;;
esac
