#!/usr/bin/env python3
"""Single waybar module for the media widget.

Everything (play/pause icon, visualizer, scrolling title, time) is rendered
into one label by one process, so it appears and disappears all at once.
Prints nothing visible (empty text) when no player is active.
"""
import html
import json
import re
import subprocess
import sys
import threading
import time

TITLE_WIDTH = 20
SCROLL_STEP = 0.3
POLL = 0.5
PLAY_ICON = "\uf04b"
PAUSE_ICON = "\uf04c"
PAUSE_PAD = 4096
BAR_COUNT = 8
TIME_WIDTH = 11
FLOOR = "▁"
BARS = "▁▂▃▄▅▆▇█"
CAVA_CONFIG = "/tmp/waybar_media_cava_config"
COLORS = "~/.config/waybar/colors/generated.css"

state = {"status": "Stopped", "title": "", "pos": 0, "length": 0}
viz = {"text": ""}


def fg_color():
    try:
        path = COLORS.replace("~", __import__("os").path.expanduser("~"))
        m = re.search(r"@define-color fg (#[0-9a-fA-F]{6});", open(path).read())
        return m.group(1) if m else None
    except OSError:
        return None


def fmt_time(us):
    s = int(us) // 1_000_000
    return f"{s // 60}:{s % 60:02d}"


def poll():
    fmt = "{{status}}\t{{artist}} - {{title}}\t{{position}}\t{{mpris:length}}"
    while True:
        try:
            out = subprocess.run(
                ["playerctl", "-p", "playerctld", "metadata", "--format", fmt],
                capture_output=True, text=True, timeout=3,
            )
            if out.returncode == 0 and out.stdout.strip():
                status, title, pos, length = (out.stdout.rstrip("\n").split("\t") + ["", "", ""])[:4]
                state.update(
                    status=status, title=title,
                    pos=int(pos or 0), length=int(length or 0),
                )
            else:
                state["status"] = "Stopped"
        except (subprocess.SubprocessError, ValueError):
            state["status"] = "Stopped"
        time.sleep(POLL)


def cava_reader():
    with open(CAVA_CONFIG, "w") as f:
        f.write(
            "[general]\nbars = 8\n\n[output]\nmethod = raw\n"
            "raw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 7\n"
        )
    proc = None
    while True:
        if state["status"] == "Playing":
            if proc is None:
                proc = subprocess.Popen(
                    ["cava", "-p", CAVA_CONFIG],
                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
                )
            line = proc.stdout.readline().strip().replace(";", "")
            viz["text"] = "".join(BARS[int(c)] for c in line if c.isdigit())
        else:
            if proc is not None:
                proc.kill()
                proc.wait()
                proc = None
            viz["text"] = ""
            time.sleep(0.2)


def scrolled(title, offset):
    if len(title) <= TITLE_WIDTH:
        return title
    loop = title + "   "
    loop = loop + loop
    i = offset % (len(title) + 3)
    return loop[i:i + TITLE_WIDTH]


def main():
    threading.Thread(target=poll, daemon=True).start()
    threading.Thread(target=cava_reader, daemon=True).start()
    fg = fg_color()
    offset, last_step, last_out = 0, time.time(), None
    last_title = ""
    while True:
        now = time.time()
        status = state["status"]
        if status in ("Playing", "Paused"):
            if state["title"] != last_title:
                last_title, offset = state["title"], 0
            if now - last_step >= SCROLL_STEP:
                offset += 1
                last_step = now
            icon = PAUSE_ICON if status == "Playing" else PLAY_ICON
            # pause glyph is narrower than play; pad it so the pill width is constant
            icon_pad = PAUSE_PAD if status == "Playing" else 0
            title = html.escape(scrolled(state["title"], offset).ljust(TITLE_WIDTH))
            if fg:
                title = f'<span foreground="{fg}">{title}</span>'
            t = f"{fmt_time(state['pos'])}/{fmt_time(state['length'])}".ljust(TIME_WIDTH)
            bars = viz["text"] if status == "Playing" else ""
            bars = bars.ljust(BAR_COUNT, FLOOR)
            text = (
                f'<span font_size="12pt" letter_spacing="{icon_pad}">{icon}</span>  '
                f'<span font_size="11pt" letter_spacing="1024">{bars}</span>  {title}  {t}'
            )
            out = {"text": text, "class": status.lower()}
        else:
            out = {"text": "", "class": "stopped"}
        line = json.dumps(out)
        if line != last_out:
            try:
                print(line, flush=True)
            except BrokenPipeError:
                sys.exit(0)
            last_out = line
        time.sleep(0.08)


if __name__ == "__main__":
    main()
