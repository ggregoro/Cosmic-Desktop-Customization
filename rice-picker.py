#!/usr/bin/env python3
"""Rice picker: a window to preview and apply the COSMIC rices in this repo.

Usage: ./rice-picker.py             open the picker
       ./rice-picker.py --install   add it to the app list and
                                    ~/.local/bin/rice-picker
       ./rice-picker.py --remove    take those away again

Pick a rice on the left to see it large on the right; Apply (or Enter,
or a double-click) runs switch-rice.sh, and Undo runs its --restore.
The Layout menu picks a panel layout to apply with the rice; "Keep mine"
leaves the panel and dock alone. The choice is remembered.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent
RICES_DIR = REPO_DIR / "rices"
LAYOUTS_DIR = REPO_DIR / "layouts"
# Menu order; any other layout folder is listed after these.
LAYOUT_ORDER = ["top-bar-autohide-dock", "top-bar-fixed-dock", "bottom-dock"]
LAYOUT_FILE = Path.home() / ".config/rice-picker/layout"
SWITCH = REPO_DIR / "switch-rice.sh"
CURRENT_FILE = Path.home() / ".config/cosmic-backups/current-rice"
BIN_LINK = Path.home() / ".local/bin/rice-picker"
APP_ID = "io.github.ggregoro.RicePicker"
# Named after the app id, so the dock matches the open window to it.
DESKTOP_FILE = Path.home() / f".local/share/applications/{APP_ID}.desktop"
OLD_DESKTOP_FILE = Path.home() / ".local/share/applications/rice-picker.desktop"
ICON_SRC = REPO_DIR / "icons" / f"{APP_ID}.svg"
ICON_FILE = Path.home() / f".local/share/icons/hicolor/scalable/apps/{APP_ID}.svg"

DESKTOP_ENTRY = f"""[Desktop Entry]
Type=Application
Name=Rice Picker
Comment=Preview and apply a COSMIC rice
Exec={BIN_LINK}
Icon={APP_ID}
Categories=Utility;DesktopSettings;
StartupWMClass={APP_ID}
"""

INSTALL_HELP = """The rice picker needs GTK 4 for Python. Install it with:
  Pop!_OS:  sudo apt install python3-gi gir1.2-gtk-4.0
  Arch:     sudo pacman -S python-gobject gtk4
  Fedora:   sudo dnf install python3-gobject gtk4"""


def install():
    BIN_LINK.parent.mkdir(parents=True, exist_ok=True)
    if BIN_LINK.is_symlink() or not BIN_LINK.exists():
        BIN_LINK.unlink(missing_ok=True)
        BIN_LINK.symlink_to(Path(__file__).resolve())
    else:
        sys.exit(f"error: {BIN_LINK} exists and is not a link; left alone")
    ICON_FILE.parent.mkdir(parents=True, exist_ok=True)
    ICON_FILE.write_bytes(ICON_SRC.read_bytes())
    DESKTOP_FILE.parent.mkdir(parents=True, exist_ok=True)
    DESKTOP_FILE.write_text(DESKTOP_ENTRY)
    # Earlier versions used another file name; drop that entry if it is ours.
    if OLD_DESKTOP_FILE.exists() and "Name=Rice Picker" in OLD_DESKTOP_FILE.read_text():
        OLD_DESKTOP_FILE.unlink()
    print(f"Added {BIN_LINK} and Rice Picker (with its icon) to the app list, under Utilities.")
    print("Open it from the app list, or add its key with ./omarchy-keys.sh --apply")
    print("(Super+Shift+Ctrl+Space, as in Omarchy).")


def remove():
    if BIN_LINK.is_symlink() and BIN_LINK.resolve() == Path(__file__).resolve():
        BIN_LINK.unlink()
    for f in (DESKTOP_FILE, OLD_DESKTOP_FILE):
        if f.exists() and "Name=Rice Picker" in f.read_text():
            f.unlink()
    if ICON_FILE.exists() and ICON_FILE.read_bytes() == ICON_SRC.read_bytes():
        ICON_FILE.unlink()
    print("Removed Rice Picker from the app list and ~/.local/bin.")


def read_rices():
    """Each rice with its screenshot and the Look / Changes text from the
    table in the main README."""
    table = {}
    readme = REPO_DIR / "README.md"
    if readme.exists():
        row = re.compile(r"^\|\s*\[`([^`]+)`\]\([^)]*\)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$")
        for line in readme.read_text().splitlines():
            m = row.match(line)
            if m:
                table[m.group(1)] = (m.group(2), m.group(3))
    rices = []
    for d in sorted(RICES_DIR.iterdir()):
        if not (d / "cosmic").is_dir():
            continue
        look, changes = table.get(d.name, ("", ""))
        try:
            layout = (d / "layout").read_text().strip()
        except OSError:
            layout = ""
        rices.append({
            "name": d.name,
            "title": d.name.replace("-", " ").title(),
            "shot": d / "screenshots" / "desktop.png",
            "look": look,
            "changes": changes,
            "layout": layout,
        })
    return rices


def read_layouts():
    """(folder name, title) for each panel layout, in menu order."""
    found = {}
    if LAYOUTS_DIR.is_dir():
        for d in LAYOUTS_DIR.iterdir():
            if (d / "cosmic").is_dir():
                try:
                    found[d.name] = (d / "title").read_text().strip()
                except OSError:
                    found[d.name] = d.name
    order = [n for n in LAYOUT_ORDER if n in found] + sorted(n for n in found if n not in LAYOUT_ORDER)
    return [(n, found[n]) for n in order]


def saved_layout():
    try:
        return LAYOUT_FILE.read_text().strip()
    except OSError:
        return ""


def save_layout(name):
    try:
        LAYOUT_FILE.parent.mkdir(parents=True, exist_ok=True)
        LAYOUT_FILE.write_text(name + "\n")
    except OSError:
        pass


def current_rice():
    try:
        return CURRENT_FILE.read_text().strip()
    except OSError:
        return ""


def needs_logout():
    """On Pop!_OS and Fedora some settings only show after logging out."""
    try:
        text = Path("/etc/os-release").read_text()
    except OSError:
        return True
    ids = re.findall(r'^(?:ID|ID_LIKE)="?([^"\n]*)', text, re.M)
    words = " ".join(ids).split()
    return not ("arch" in words)


def in_vm():
    """True inside a virtual machine (systemd-detect-virt --vm)."""
    try:
        return subprocess.run(["systemd-detect-virt", "--vm", "--quiet"]).returncode == 0
    except OSError:
        return False


def run_app():
    # VirtualBox and other VMs draw GTK 4 windows wrongly with the
    # graphics card, so draw in software there. A GSK_RENDERER the
    # user set themselves still wins.
    if "GSK_RENDERER" not in os.environ and in_vm():
        os.environ["GSK_RENDERER"] = "cairo"
    try:
        import gi
        gi.require_version("Gtk", "4.0")
        gi.require_version("Gdk", "4.0")
        from gi.repository import Gdk, Gio, GLib, Gtk
    except (ImportError, ValueError):
        sys.exit(INSTALL_HELP)

    Gtk.Window.set_default_icon_name(APP_ID)

    class Picker(Gtk.ApplicationWindow):
        def __init__(self, app):
            super().__init__(application=app, title="Rice Picker")
            self.set_default_size(1100, 640)
            self.rices = read_rices()
            self.layouts = read_layouts()
            self.busy = False

            keys = Gtk.EventControllerKey()
            keys.connect("key-pressed", self.on_key)
            self.add_controller(keys)

            paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
            paned.set_position(400)
            self.set_child(paned)

            # Left: one card per rice.
            self.flow = Gtk.FlowBox(selection_mode=Gtk.SelectionMode.SINGLE,
                                    max_children_per_line=2, min_children_per_line=1,
                                    homogeneous=True, row_spacing=12, column_spacing=12,
                                    valign=Gtk.Align.START,
                                    activate_on_single_click=False)
            for m in ("top", "bottom", "start", "end"):
                getattr(self.flow, f"set_margin_{m}")(12)
            self.cards = []
            for r in self.rices:
                box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
                pic = Gtk.Picture(can_shrink=True)
                pic.set_size_request(170, 96)
                pic.set_content_fit(Gtk.ContentFit.COVER)
                if r["shot"].exists():
                    pic.set_filename(str(r["shot"]))
                label = Gtk.Label(xalign=0)
                box.append(pic)
                box.append(label)
                self.flow.append(box)
                self.cards.append(label)
            self.flow.connect("selected-children-changed", self.on_select)
            # One click only shows a rice; Apply, Enter or a double-click applies it.
            self.flow.connect("child-activated", lambda *_: self.apply())
            scroll = Gtk.ScrolledWindow(child=self.flow)
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            paned.set_start_child(scroll)
            paned.set_shrink_start_child(False)

            # Right: large preview, text and buttons.
            side = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            for m in ("top", "bottom", "start", "end"):
                getattr(side, f"set_margin_{m}")(16)
            self.preview = Gtk.Picture(can_shrink=True, vexpand=True)
            self.preview.set_size_request(-1, 220)
            self.preview.set_content_fit(Gtk.ContentFit.CONTAIN)
            self.title = Gtk.Label(xalign=0)
            self.look = Gtk.Label(xalign=0, wrap=True)
            self.changes = Gtk.Label(xalign=0, wrap=True)
            self.changes.add_css_class("dim-label")
            self.status = Gtk.Label(xalign=0, wrap=True, selectable=True)

            # Panel layout to apply with the rice; "Keep mine" first.
            layout_row = Gtk.Box(spacing=8)
            layout_row.append(Gtk.Label(label="Layout:"))
            self.layout_menu = Gtk.DropDown.new_from_strings(
                ["Keep mine"] + [t for _, t in self.layouts])
            names = [n for n, _ in self.layouts]
            keep = saved_layout()
            if keep in names:
                self.layout_menu.set_selected(names.index(keep) + 1)
            self.layout_menu.connect("notify::selected", lambda *_: save_layout(self.layout_name() or "keep"))
            self.layout_hint = Gtk.Label(xalign=0)
            self.layout_hint.add_css_class("dim-label")
            layout_row.append(self.layout_menu)
            layout_row.append(self.layout_hint)

            buttons = Gtk.Box(spacing=8)
            self.apply_btn = Gtk.Button(label="Apply")
            self.apply_btn.add_css_class("suggested-action")
            self.apply_btn.connect("clicked", lambda *_: self.apply())
            self.undo_btn = Gtk.Button(label="Undo last switch")
            self.undo_btn.connect("clicked", lambda *_: self.undo())
            self.spinner = Gtk.Spinner()
            buttons.append(self.apply_btn)
            buttons.append(self.undo_btn)
            buttons.append(self.spinner)

            # Messages scroll, so a long one never squeezes the preview.
            status_scroll = Gtk.ScrolledWindow(child=self.status)
            status_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            status_scroll.set_min_content_height(70)
            status_scroll.set_max_content_height(110)
            status_scroll.set_propagate_natural_height(True)
            for w in (self.preview, self.title, self.look, self.changes, layout_row, buttons, status_scroll):
                side.append(w)
            paned.set_end_child(side)
            paned.set_shrink_end_child(False)

            self.refresh_cards()
            names = [r["name"] for r in self.rices]
            cur = current_rice()
            start = names.index(cur) if cur in names else 0
            if self.rices:
                first = self.flow.get_child_at_index(start)
                self.flow.select_child(first)
                # Focus the card once the window is up, so the arrow keys
                # move between rices straight away.
                self.connect("map", lambda *_: GLib.idle_add(lambda: first.grab_focus() and False))

        def layout_name(self):
            i = self.layout_menu.get_selected()
            return self.layouts[i - 1][0] if 0 < i <= len(self.layouts) else ""

        def selected(self):
            kids = self.flow.get_selected_children()
            return self.rices[kids[0].get_index()] if kids else None

        def refresh_cards(self):
            cur = current_rice()
            for r, label in zip(self.rices, self.cards):
                mark = "  ✓ current" if r["name"] == cur else ""
                label.set_markup(f"<b>{GLib.markup_escape_text(r['title'])}</b>{mark}")

        def on_select(self, *_):
            r = self.selected()
            if not r:
                return
            if r["shot"].exists():
                self.preview.set_filename(str(r["shot"]))
            else:
                self.preview.set_paintable(None)
            esc = GLib.markup_escape_text
            self.title.set_markup(f"<big><b>{esc(r['title'])}</b></big>")
            self.look.set_text(r["look"])
            note = r["changes"]
            self.changes.set_text(f"Changes: {note}" if note else "")
            titles = dict(self.layouts)
            hint = titles.get(r["layout"], "")
            self.layout_hint.set_text(f"(suggested: {hint})" if hint else "")

        def on_key(self, _ctrl, keyval, _code, _state):
            if keyval == Gdk.KEY_Escape:
                self.close()
                return True
            return False

        def run_switch(self, args, done_text):
            if self.busy:
                return
            self.busy = True
            self.apply_btn.set_sensitive(False)
            self.undo_btn.set_sensitive(False)
            self.spinner.start()
            self.status.set_text("Working ...")
            proc = Gio.Subprocess.new(
                [str(SWITCH)] + args,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_MERGE)

            def finished(p, res):
                ok, out, _ = p.communicate_utf8_finish(res)
                self.busy = False
                self.spinner.stop()
                self.apply_btn.set_sensitive(True)
                self.undo_btn.set_sensitive(True)
                self.refresh_cards()
                notes = [l for l in (out or "").splitlines()
                         if l.startswith(("warning", "error", "note", "  "))]
                if p.get_successful():
                    msg = done_text
                    if needs_logout():
                        msg += "\nIf something has not changed, log out and back in."
                else:
                    msg = "Something went wrong:"
                    notes = (out or "").strip().splitlines()[-8:]
                self.status.set_text("\n".join([msg] + notes))

            proc.communicate_utf8_async(None, None, finished)

        def apply(self):
            r = self.selected()
            if r:
                layout = self.layout_name()
                args = [r["name"]] + (["--layout", layout] if layout else [])
                done = f"{r['title']} applied"
                if layout:
                    done += f" with the {dict(self.layouts)[layout]} layout"
                self.run_switch(args, done + ".")

        def undo(self):
            self.run_switch(["--restore"], "Went back to the settings from before the last switch.")

    app = Gtk.Application(application_id=APP_ID, flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

    def activate(a):
        win = a.get_active_window() or Picker(a)
        win.present()

    app.connect("activate", activate)
    return app.run([sys.argv[0]])


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "--install":
            install()
        elif sys.argv[1] == "--remove":
            remove()
        else:
            print(__doc__.strip())
            sys.exit(0 if sys.argv[1] in ("-h", "--help") else 1)
    else:
        sys.exit(run_app())
