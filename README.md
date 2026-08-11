# Cosmic Desktop Customization

Tracked configuration for a redesigned [COSMIC](https://system76.com/cosmic) desktop
on Pop!_OS. This repo is a subset of `~/.config` — only the `cosmic/` directory is
tracked (see `.gitignore`); everything else under `~/.config` (browser profiles, app
caches, unrelated app settings) is deliberately left out.

## System

- Pop!_OS 24.04 LTS, `apt`
- COSMIC desktop environment, `cosmic-comp` compositor, Wayland
- Intel HD Graphics 5500 (`i915`)

## What changed from stock COSMIC

**Theme & icons** — [Yaru](https://github.com/ubuntu/yaru) GTK theme and icon set,
applied two ways:
- `gsettings` (`org.gnome.desktop.interface` `gtk-theme` / `icon-theme`) for
  legacy/Flatpak GTK apps — not file-based, so not tracked here; see "Packages" below.
- `cosmic/com.system76.CosmicTk/v1/icon_theme` for native COSMIC apps
  (Files, Settings, panel, dock).

**Wallpaper** — `cosmic/com.system76.CosmicBackground/v1/all`, a Milky Way core photo
by [Jeremy Thomas on Unsplash](https://unsplash.com/photos/blue-and-purple-galaxy-digital-wallpaper-E0AHdsENmDg)
(Unsplash License — free to use, no attribution required). The image file itself
lives at `~/Pictures/milky-way-core-jeremy-thomas-unsplash.jpg`, outside this repo.

**Dock/panel** — the top panel was removed entirely
(`cosmic/com.system76.CosmicPanel/v1/entries`); every applet it used to carry now
lives in the bottom dock instead (`cosmic/com.system76.CosmicPanel.Dock/v1/`):

- Left side: app launcher, workspace overview, pinned/running apps, window minimize
- Right side: workspace switcher, clipboard manager, weather (Tempest applet),
  volume, Bluetooth, network, battery, power/shutdown, clock — in that order
- Persistent (`autohide: Never`) and reserves screen space (`exclusive_zone: true`)
  so windows never render underneath it
- Spans the full width of the screen (`expand_to_edges: true`), flush against the
  bottom edge (`anchor_gap: false`, `margin: 0`), square corners (`border_radius: 0`)
- Size `XS` (smallest step on COSMIC's XS/S/M/L/XL scale)

**Appearance style** — set via COSMIC Settings' Desktop > Appearance > Style panel
(not hand-edited): square window corners (`corner_radii`, all tiers at `2.0`) and a
small tiling gap (`gaps`, `(0, 3)` — `3` is the minimum allowed above the hint-frame
width of `2`), tracked under `cosmic/com.system76.CosmicTheme.{Dark,Light}{,.Builder}/`.

## Packages required

| Package | Reason |
|---|---|
| `yaru-theme-gtk` | Yaru GTK theme |
| `yaru-theme-icon` | Yaru icon set |

Both install via `apt` on Pop!_OS/Ubuntu-based distros — no PPA needed.

After installing, the GTK/icon theme still needs to be selected (not tracked here,
since it's `dconf` state, not a file):

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
```

## Restoring / reverting

- `git log` shows the full history from `pre-claude-baseline` (the state of
  `~/.config/cosmic` before this project started) through every change since.
- Full revert: `git checkout pre-claude-baseline -- cosmic/`
- Package removal: `sudo apt remove yaru-theme-gtk yaru-theme-icon`

COSMIC's settings daemon watches these config files live — most changes apply
within a second or two of a file being written, no reload or logout needed.
