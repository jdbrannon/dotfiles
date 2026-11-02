#!/usr/bin/env python3
"""Read-only month calendar popup backed by khal. Run via calendar-toggle.sh."""
import calendar
import glob
import os
import re
import subprocess
import threading
from datetime import date, datetime, timedelta

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell as LayerShell  # noqa: E402

HOME = os.path.expanduser("~")
COLORS_CSS = f"{HOME}/.config/waybar/colors/generated.css"
ICS_GLOB = f"{HOME}/.local/share/khal/calendars/*/*.ics"
DEFAULT_DOT = "#888888"

CSS = """
window { background: transparent; }
.popup { background: @bg0; color: @fg; border: 1px solid @bg3; border-radius: 14px; padding: 14px; }
.title { font-weight: bold; font-size: 15px; }
.nav, .day { background: transparent; color: @fg; border: none; border-radius: 8px; padding: 2px; min-width: 0; min-height: 0; box-shadow: none; }
.nav { padding: 2px 10px; }
.nav:hover, .day:hover { background: @bg4; }
.dow { color: @grey0; font-size: 11px; }
.other { color: @grey0; opacity: 0.5; }
.today { background: @primary_container; }
.selected { background: @primary; color: @bg1; }
.selected .daynum { color: @bg1; }
.today.selected .daynum { color: @bg1; }
.status { color: @grey0; font-size: 11px; }
.events { color: @fg; }
.eventhead { font-weight: bold; }
separator { background: @bg3; min-height: 1px; margin: 8px 0; }
"""


def load_event_colors():
    colors = {}
    for path in glob.glob(ICS_GLOB):
        uid = color = None
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.rstrip("\r\n")
                    if line.startswith("UID:"):
                        uid = line[4:]
                    elif line.startswith("COLOR:"):
                        color = line[6:]
        except OSError:
            continue
        if uid and color and re.fullmatch(r"[A-Za-z0-9#]+", color):
            colors[uid] = color
    return colors


def load_events(start, end):
    """Returns {date: [(color, time_text, title)]} for start..end inclusive."""
    fmt = "%m/%d/%Y"
    colors = load_event_colors()
    out = subprocess.run(
        ["khal", "list", start.strftime(fmt), end.strftime(fmt),
         "--day-format", "DAY:{date}",
         "--format", "{uid}|{start-end-time-style}|{title}"],
        capture_output=True, text=True,
    ).stdout
    events = {}
    day = None
    for line in out.splitlines():
        if line.startswith("DAY:"):
            day = datetime.strptime(line[4:].strip(), fmt).date()
        elif day and "|" in line:
            uid, when, title = line.split("|", 2)
            events.setdefault(day, []).append((colors.get(uid, DEFAULT_DOT), when, title))
    return events


def esc(text):
    return GLib.markup_escape_text(text)


class Popup(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.jdbrannon.CalendarPopup")
        self.today = date.today()
        self.selected = self.today
        self.year, self.month = self.today.year, self.today.month
        self.events = {}
        self.syncing = False
        self.last_scroll = 0
        self.grace_until = 0

    def do_activate(self):
        provider = Gtk.CssProvider()
        css = ""
        try:
            with open(COLORS_CSS) as f:
                css = f.read()
        except OSError:
            css = "@define-color bg0 #1e1e1e; @define-color bg1 #141414; @define-color bg3 #444; @define-color bg4 #333; @define-color fg #eee; @define-color grey0 #999; @define-color primary #8ecbff; @define-color primary_container #345;"
        provider.load_from_string(css + CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.win = Gtk.ApplicationWindow(application=self)
        LayerShell.init_for_window(self.win)
        LayerShell.set_layer(self.win, LayerShell.Layer.OVERLAY)
        LayerShell.set_anchor(self.win, LayerShell.Edge.TOP, True)
        LayerShell.set_anchor(self.win, LayerShell.Edge.RIGHT, True)
        LayerShell.set_margin(self.win, LayerShell.Edge.TOP, 6)
        LayerShell.set_margin(self.win, LayerShell.Edge.RIGHT, 12)
        LayerShell.set_keyboard_mode(self.win, LayerShell.KeyboardMode.ON_DEMAND)

        self.root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.root.add_css_class("popup")
        self.root.set_size_request(340, -1)
        self.win.set_child(self.root)
        self.build_header()
        self.body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.root.append(self.body)

        keys = Gtk.EventControllerKey()
        keys.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        keys.connect("key-pressed", self.on_key)
        self.win.add_controller(keys)
        scroll = Gtk.EventControllerScroll(flags=Gtk.EventControllerScrollFlags.VERTICAL)
        scroll.connect("scroll", self.on_scroll)
        self.win.add_controller(scroll)

        self.opened = False
        self.win.connect("notify::is-active", self.on_active)
        self.render()
        self.win.present()
        self.load_async()
        self.sync()

    def on_active(self, win, _pspec):
        if win.is_active():
            self.opened = True
        elif self.opened:
            # Dropdown menus are separate surfaces that briefly take focus.
            GLib.timeout_add(250, self.close_if_inactive)

    def pick_grace(self):
        # Closing a dropdown menu briefly leaves no window focused.
        self.grace_until = GLib.get_monotonic_time() + 1_500_000

    def dropdown_open(self):
        for dd in (self.month_dd, self.year_dd):
            child = dd.get_first_child()
            while child:
                if isinstance(child, Gtk.Popover) and child.get_visible():
                    return True
                child = child.get_next_sibling()
        return False

    def close_if_inactive(self):
        if self.win.is_active():
            return False
        if self.dropdown_open() or GLib.get_monotonic_time() < self.grace_until:
            return True
        self.quit()
        return False

    def on_key(self, _ctl, keyval, _code, _state):
        name = Gdk.keyval_name(keyval)
        if name in ("Escape", "q"):
            self.quit()
        elif name in ("Left", "h"):
            self.shift_month(-1)
        elif name in ("Right", "l"):
            self.shift_month(1)
        elif name in ("Up", "k"):
            self.shift_month(-12)
        elif name in ("Down", "j"):
            self.shift_month(12)
        elif name in ("t", "Return", "KP_Enter"):
            self.goto(self.today)
        else:
            return False
        return True

    def on_scroll(self, _ctl, _dx, dy):
        now = GLib.get_monotonic_time()
        if now - self.last_scroll > 150_000:
            self.last_scroll = now
            self.shift_month(1 if dy > 0 else -1)
        return True

    def shift_month(self, delta):
        index = self.year * 12 + (self.month - 1) + delta
        self.year, self.month = index // 12, index % 12 + 1
        self.reload()

    def goto(self, day):
        self.selected = day
        self.year, self.month = day.year, day.month
        self.reload()

    def sync(self):
        if self.syncing:
            return
        self.syncing = True
        self.render()

        def work():
            subprocess.run(["vdirsyncer", "sync"], capture_output=True)
            GLib.idle_add(self.done_sync)

        threading.Thread(target=work, daemon=True).start()

    def done_sync(self):
        self.syncing = False
        self.load_async()

    def load_async(self):
        """Loads a wide date range once off the UI thread; month changes then use the cache."""
        def work():
            events = load_events(self.today - timedelta(days=400), self.today + timedelta(days=800))
            GLib.idle_add(self.loaded, events)

        threading.Thread(target=work, daemon=True).start()

    def loaded(self, events):
        self.events = events
        self.render()

    def reload(self):
        self.render()

    def month_weeks(self):
        # Always 6 rows so the popup height doesn't change between months.
        weeks = calendar.Calendar(firstweekday=6).monthdatescalendar(self.year, self.month)
        while len(weeks) < 6:
            weeks.append([d + timedelta(days=7) for d in weeks[-1]])
        return weeks

    def build_header(self):
        header = Gtk.Box(spacing=4)
        prev = Gtk.Button(label="‹")
        prev.add_css_class("nav")
        prev.connect("clicked", lambda *_: self.shift_month(-1))
        nxt = Gtk.Button(label="›")
        nxt.add_css_class("nav")
        nxt.connect("clicked", lambda *_: self.shift_month(1))
        self.month_names = [calendar.month_name[m] for m in range(1, 13)]
        self.month_dd = Gtk.DropDown.new_from_strings(self.month_names)
        self.month_dd.set_hexpand(True)
        longest = max(self.month_names, key=lambda n: self.month_dd.create_pango_layout(n).get_pixel_size()[0])
        width = self.month_dd.create_pango_layout(longest).get_pixel_size()[0]
        self.month_dd.set_size_request(width + 56, -1)
        self.month_dd.connect("notify::selected", self.on_month_picked)
        self.year_dd = Gtk.DropDown()
        self.year_dd.connect("notify::selected", self.on_year_picked)
        self.year_range = None
        today_btn = Gtk.Button(label="Today")
        today_btn.add_css_class("nav")
        today_btn.connect("clicked", lambda *_: self.goto(self.today))
        for w in (prev, self.month_dd, self.year_dd, nxt, today_btn):
            header.append(w)
        self.root.append(header)

    def sync_header(self):
        self.updating_header = True
        first = min(self.today.year, self.year) - 5
        last = max(self.today.year, self.year) + 5
        if self.year_range != (first, last):
            self.year_range = (first, last)
            self.year_dd.set_model(Gtk.StringList.new([str(y) for y in range(first, last + 1)]))
        self.month_dd.set_selected(self.month - 1)
        self.year_dd.set_selected(self.year - first)
        self.updating_header = False

    def on_month_picked(self, dd, _pspec):
        if not getattr(self, "updating_header", False) and dd.get_selected() + 1 != self.month:
            self.pick_grace()
            self.month = dd.get_selected() + 1
            self.render()

    def on_year_picked(self, dd, _pspec):
        if not getattr(self, "updating_header", False) and self.year_range:
            year = self.year_range[0] + dd.get_selected()
            if year != self.year:
                self.pick_grace()
                self.year = year
                self.render()

    def render(self):
        while child := self.body.get_first_child():
            self.body.remove(child)
        self.sync_header()

        grid = Gtk.Grid(column_homogeneous=True, row_spacing=2, column_spacing=2)
        grid.set_margin_top(8)
        for i, name in enumerate(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]):
            lbl = Gtk.Label(label=name)
            lbl.add_css_class("dow")
            grid.attach(lbl, i, 0, 1, 1)
        weeks = self.month_weeks()
        for r, week in enumerate(weeks, start=1):
            for c, day in enumerate(week):
                grid.attach(self.day_button(day), c, r, 1, 1)
        self.body.append(grid)

        self.body.append(Gtk.Separator())
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroller.set_min_content_height(150)
        scroller.set_max_content_height(150)
        scroller.set_child(self.events_view())
        self.body.append(scroller)

        status = Gtk.Label(label="Syncing…" if self.syncing else "←/→ month · ↑/↓ year · Enter today · Esc close", xalign=0)
        status.add_css_class("status")
        status.set_margin_top(8)
        self.body.append(status)

    def day_button(self, day):
        btn = Gtk.Button()
        btn.add_css_class("day")
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        num = Gtk.Label(label=str(day.day))
        num.add_css_class("daynum")
        if day.month != self.month:
            num.add_css_class("other")
        box.append(num)
        dots = self.events.get(day, [])
        seen = []
        for color, _, _ in dots:
            if color not in seen:
                seen.append(color)
        marks = "".join(f"<span foreground='{c}'>●</span>" for c in seen[:3])
        dot_label = Gtk.Label(use_markup=True, label=f"<span size='x-small'>{marks or ' '}</span>")
        box.append(dot_label)
        btn.set_child(box)
        if day == self.today:
            btn.add_css_class("today")
        if day == self.selected:
            btn.add_css_class("selected")
        btn.connect("clicked", lambda *_: self.select(day))
        return btn

    def select(self, day):
        self.selected = day
        if (day.year, day.month) != (self.year, self.month):
            self.year, self.month = day.year, day.month
            self.reload()
        else:
            self.render()

    def events_view(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        box.add_css_class("events")
        head = Gtk.Label(label=self.selected.strftime("%A, %B %-d"), xalign=0)
        head.add_css_class("eventhead")
        box.append(head)
        items = self.events.get(self.selected, [])
        if not items:
            lbl = Gtk.Label(label="No events", xalign=0)
            lbl.add_css_class("status")
            box.append(lbl)
        for color, when, title in items:
            lbl = Gtk.Label(use_markup=True, xalign=0, wrap=True,
                            label=f"<span foreground='{color}'>●</span> {esc(when)} {esc(title)}")
            box.append(lbl)
        return box


if __name__ == "__main__":
    Popup().run()
