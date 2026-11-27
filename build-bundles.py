#!/usr/bin/env python3
"""Build a COSMIC theme bundle (.zip) for each rice.

Newer COSMIC Settings (Settings > Appearance > Import) installs a look
from a "theme bundle": a zip holding the theme, its builder settings and
the wallpaper. This script makes those zips from the rice files, so the
rice files stay the only thing to edit and the zips never go stale.

Usage:
  ./build-bundles.py                 build every rice into bundles/
  ./build-bundles.py onyx downtown   build only these rices
  ./build-bundles.py --out DIR       write the zips somewhere else
  ./build-bundles.py --install onyx  install and switch on the rice's
                                     bundles directly (switch-rice.sh uses
                                     this on newer COSMIC Settings); prints
                                     the files it wrote

Each rice gives one zip per mode it has: <rice>.zip for dark, and
<rice>-light.zip for rices with light-mode files.

What a bundle does not carry, on purpose: window border size, gaps and
frosted glass. COSMIC keeps those as the user's own settings. Panel
layouts, GTK theme, terminal colours and keys aren't part of a bundle
either; the rice picker still does those.
"""

import argparse
import re
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

REPO_DIR = Path(__file__).resolve().parent
RICES_DIR = REPO_DIR / "rices"
BUNDLE = "com.system76.CosmicThemeBundle"

# Settings that belong to the user, not to a look. COSMIC never takes
# them from a bundle (theme-bundle-config INTERFACE_KEYS), so leave them out.
INTERFACE_KEYS = {
    "active_hint", "spacing", "gaps", "frosted", "frosted_windows",
    "frosted_system_interface", "frosted_panel", "frosted_applets",
    "frosted_maximized_apps", "alpha_map",
}

# Builder colours COSMIC derives the whole theme from when a bundle is
# switched on. The rices only store some builder keys, so these come from
# the matching theme file's top-level base colour.
DERIVED = {
    "bg_color": "background",
    "primary_container_bg": "primary",
    "secondary_container_bg": "secondary",
}

TEXT = zipfile.ZIP_DEFLATED
BINARY = zipfile.ZIP_STORED


def title_of(rice):
    """Same title the rice picker shows."""
    return rice.replace("-", " ").title()


def top_base(text):
    """The first base: "#RRGGBBAA" in a theme file."""
    m = re.search(r'base:\s*"(#[0-9A-Fa-f]{8})"', text)
    return m.group(1) if m else None


def key_files(folder):
    if not folder.is_dir():
        return {}
    return {f.name: f.read_text() for f in sorted(folder.iterdir()) if f.is_file()}


def metainfo(slug, name, mode, wallpaper_dir, has_background=True):
    parts = "Theme,Builder,Background" if has_background else "Theme,Builder"
    asset = ""
    if wallpaper_dir:
        asset = (f'[(id:"{BUNDLE}.{slug}.wallpapers",kind:Wallpaper,'
                 f'path:"{wallpaper_dir}",name:"{slug}")]')
    else:
        asset = "[]"
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<component type="generic">
  <id>{BUNDLE}.{slug}</id>
  <name>{escape(name)}</name>
  <summary>Cosmic theme bundle</summary>
  <description>
    <p>A COSMIC theme bundle carrying the complete look for one mode: the theme, its builder settings, and the background it is shown with.</p>
  </description>
  <metadata_license>CC0-1.0</metadata_license>
  <icon type="stock">preferences-other-symbolic</icon>
  <custom>
    <value key="x-cosmic-format">1</value>
    <value key="x-cosmic-version">1.0.0</value>
    <value key="x-cosmic-slug">{slug}</value>
    <value key="x-cosmic-mode">{mode.lower()}</value>
    <value key="x-cosmic-parts">{parts}</value>
    <value key="x-cosmic-assets">{escape(asset)}</value>
  </custom>
</component>
"""


def collect(rice_dir, mode):
    """Everything a bundle for one mode of a rice holds, or None if the
    rice has no theme for that mode. The background's source is left as
    WALLPAPER_PATH for the caller to fill in."""
    rice = rice_dir.name
    cosmic = rice_dir / "cosmic"
    theme = key_files(cosmic / f"com.system76.CosmicTheme.{mode}" / "v2")
    if not theme:
        return None
    builder = key_files(cosmic / f"com.system76.CosmicTheme.{mode}.Builder" / "v2")

    name = title_of(rice) + ("" if mode == "Dark" else " Light")
    slug = rice if mode == "Dark" else f"{rice}-light"

    theme = {k: v for k, v in theme.items() if k not in INTERFACE_KEYS}
    builder = {k: v for k, v in builder.items() if k not in INTERFACE_KEYS}
    theme["name"] = f'"{name}"'
    theme["is_dark"] = "true" if mode == "Dark" else "false"

    for key, theme_key in DERIVED.items():
        if key not in builder and theme_key in theme:
            colour = top_base(theme[theme_key])
            if colour:
                builder[key] = f'Some("{colour}")'

    # COSMIC now reads the icon theme and monospace font from the theme,
    # not from CosmicTk.
    icon_file = rice_dir / "icon-theme"
    if icon_file.is_file():
        icon = icon_file.read_text().strip()
        theme["icon_theme"] = builder["icon_theme"] = f'"{icon}"'
    mono = cosmic / "com.system76.CosmicTk" / "v1" / "monospace_font"
    if mono.is_file():
        theme["mono_font"] = builder["mono_font"] = mono.read_text()

    # Wallpaper: the image the rice's background points at.
    wallpaper = None
    background = None
    bg_file = cosmic / "com.system76.CosmicBackground" / "v1" / "all"
    if bg_file.is_file():
        background = bg_file.read_text()
        m = re.search(r'source:\s*Path\("([^"]*)"\)', background)
        if m:
            candidate = rice_dir / "wallpaper" / Path(m.group(1)).name
            if candidate.is_file():
                wallpaper = candidate
                background = re.sub(r'source:\s*Path\("[^"]*"\)',
                                    'source: Path("WALLPAPER_PATH")', background)

    return {"slug": slug, "name": name, "mode": mode, "theme": theme,
            "builder": builder, "background": background, "wallpaper": wallpaper}


def write_zip(b, out_dir):
    slug = b["slug"]
    wallpaper = b["wallpaper"]
    wallpaper_dir = f"data/cosmic/{slug}/wallpapers" if wallpaper else None
    background = b["background"]
    if background and wallpaper:
        background = background.replace("WALLPAPER_PATH", f"{wallpaper_dir}/{wallpaper.name}")

    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"{slug}.zip"
    root = f"config/cosmic/{BUNDLE}.{slug}"
    with zipfile.ZipFile(zip_path, "w") as z:
        def add(path, body, kind=TEXT):
            info = zipfile.ZipInfo(path, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = kind
            info.external_attr = 0o644 << 16
            z.writestr(info, body)

        add(f"{BUNDLE}.{slug}.metainfo.xml", metainfo(slug, b["name"], b["mode"], wallpaper_dir, bool(background)))
        for key, value in sorted(b["theme"].items()):
            add(f"{root}.Theme/v2/{key}", value)
        for key, value in sorted(b["builder"].items()):
            add(f"{root}.Builder/v2/{key}", value)
        if background:
            add(f"{root}.Background/v1/base", background)
            add(f"{root}.Background/v1/same-on-all", "true")
        if wallpaper:
            add(f"{wallpaper_dir}/{wallpaper.name}", wallpaper.read_bytes(), BINARY)
    return zip_path


def install(b, config_dir, data_dir):
    """Install the bundle the way Settings' Import does, then make it the
    live look for its mode (what Settings does when you click its card).
    Interface keys (border, gaps, frosted glass) are left as they are.
    Returns the files written under config_dir, relative to it."""
    slug, mode = b["slug"], b["mode"]
    written = []

    def put(rel, body):
        path = config_dir / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body)
        written.append(rel)

    background = b["background"]
    if b["wallpaper"]:
        wp_dir = data_dir / f"{BUNDLE}.{slug}.wallpapers"
        wp_dir.mkdir(parents=True, exist_ok=True)
        target = wp_dir / b["wallpaper"].name
        target.write_bytes(b["wallpaper"].read_bytes())
        background = background.replace("WALLPAPER_PATH", str(target))

    # The bundle, as Import leaves it.
    for key, value in b["theme"].items():
        put(f"{BUNDLE}.{slug}.Theme/v2/{key}", value)
    for key, value in b["builder"].items():
        put(f"{BUNDLE}.{slug}.Builder/v2/{key}", value)
    if background:
        put(f"{BUNDLE}.{slug}.Background/v1/base", background)
        put(f"{BUNDLE}.{slug}.Background/v1/same-on-all", "true")
    put(f"{BUNDLE}.{slug}.Package/v1/package_id", f'"{BUNDLE}.{slug}"')
    put(f"{BUNDLE}.{slug}.Package/v1/version", '"1.0.0"')

    # Make it live. Settings finds the active bundle by the live theme's
    # name, so the name must match.
    for key, value in b["theme"].items():
        put(f"com.system76.CosmicTheme.{mode}/v2/{key}", value)
    for key, value in b["builder"].items():
        put(f"com.system76.CosmicTheme.{mode}.Builder/v2/{key}", value)
    if background:
        put(f"com.system76.CosmicBackground.{mode}/v1/all", background)
        put(f"com.system76.CosmicBackground.{mode}/v1/base", background)
        put(f"com.system76.CosmicBackground.{mode}/v1/same-on-all", "true")
        put(f"com.system76.CosmicBackground.{mode}/v1/backgrounds", "[]")
    return written


def main():
    parser = argparse.ArgumentParser(description="Build COSMIC theme bundles from the rices.")
    parser.add_argument("rices", nargs="*", help="rice names (default: all)")
    parser.add_argument("--out", default=str(REPO_DIR / "bundles"), help="output folder")
    parser.add_argument("--install", action="store_true",
                        help="install the rice's bundles into ~/.config/cosmic and make "
                             "them live, instead of writing zips (used by switch-rice.sh "
                             "on newer COSMIC Settings)")
    args = parser.parse_args()

    names = args.rices or sorted(d.name for d in RICES_DIR.iterdir() if (d / "cosmic").is_dir())
    out_dir = Path(args.out)
    home = Path.home()
    config_dir = home / ".config" / "cosmic"
    data_dir = home / ".local" / "share" / "cosmic"
    failed = False
    for rice in names:
        rice_dir = RICES_DIR / rice
        if not (rice_dir / "cosmic").is_dir():
            print(f"error: no rice named '{rice}'", file=sys.stderr)
            failed = True
            continue
        for mode in ("Dark", "Light"):
            b = collect(rice_dir, mode)
            if not b:
                continue
            if args.install:
                for rel in install(b, config_dir, data_dir):
                    print(rel)
            else:
                path = write_zip(b, out_dir)
                shown = path.relative_to(REPO_DIR) if path.is_relative_to(REPO_DIR) else path
                print(f"built {shown}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
