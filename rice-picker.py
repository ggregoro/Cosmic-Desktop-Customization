#!/usr/bin/env python3
"""Rice picker: a window to preview and apply the COSMIC rices in this repo.

Usage: ./rice-picker.py             open the picker
       ./rice-picker.py --install   add it to the app list and
                                    ~/.local/bin/rice-picker
       ./rice-picker.py --remove    take those away again

Pick a rice on the left to see it large on the right; Apply (or Enter,
or a double-click) runs switch-rice.sh, and Undo runs its --restore.
"""

import os
import re
import sys
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent
RICES_DIR = REPO_DIR / "rices"
SWITCH = REPO_DIR / "switch-rice.sh"
CURRENT_FILE = Path.home() / ".config/cosmic-backups/current-rice"
BIN_LINK = Path.home() / ".local/bin/rice-picker"
DESKTOP_FILE = Path.home() / ".local/share/applications/rice-picker.desktop"
APP_ID = "io.github.ggregoro.RicePicker"

DESKTOP_ENTRY = f"""[Desktop Entry]
Type=Application
Name=Rice Picker
Comment=Preview and apply a COSMIC rice
Exec={BIN_LINK}
Icon=preferences-desktop-theme
Categories=Settings;DesktopSettings;
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
    DESKTOP_FILE.parent.mkdir(parents=True, exist_ok=True)
    DESKTOP_FILE.write_text(DESKTOP_ENTRY)
    print(f"Added {BIN_LINK} and Rice Picker to the app list.")
    print("Open it from the app list, or add its key with ./omarchy-keys.sh --apply")
    print("(Super+Shift+Ctrl+Space, as in Omarchy).")


def remove():
    if BIN_LINK.is_symlink() and BIN_LINK.resolve() == Path(__file__).resolve():
        BIN_LINK.unlink()
    if DESKTOP_FILE.exists() and DESKTOP_FILE.read_text() == DESKTOP_ENTRY:
        DESKTOP_FILE.unlink()
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
        rices.append({
            "name": d.name,
            "title": d.name.replace("-", " ").title(),
            "shot": d / "screenshots" / "desktop.png",
            "look": look,
            "changes": changes,
        })
    return rices


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


def run_app():
    try:
        import gi
        gi.require_version("Gtk", "4.0")
        gi.require_version("Gdk", "4.0")
        from gi.repository import Gdk, Gio, GLib, Gtk
    except (ImportError, ValueError):
        sys.exit(INSTALL_HELP)

    class Picker(Gtk.ApplicationWindow):
        def __init__(self, app):
            super().__init__(application=app, title="Rice Picker")
            self.set_default_size(1100, 640)
            self.rices = read_rices()
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
                                    valign=Gtk.Align.START)
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
            for w in (self.preview, self.title, self.look, self.changes, buttons, status_scroll):
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
            if "panel" in note.lower():
                note += ". This one also changes your panel and dock."
            self.changes.set_text(f"Changes: {note}" if note else "")

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
                self.run_switch([r["name"]], f"{r['title']} applied.")

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
