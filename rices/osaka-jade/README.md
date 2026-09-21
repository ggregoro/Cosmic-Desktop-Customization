# Osaka Jade rice

One of several rices in this repo — see the [top-level README](../../README.md) for
the full list. Captured 2026-09-15 from the Dell E7450 laptop, which had just been
switched from GNOME to **COSMIC via Fedora's COSMIC Spin** (Fedora Linux 44 stays
the base OS/distro — only the desktop environment changed). This directory is a
snapshot of `~/.config/cosmic` at that point (see `../../.gitignore` for the two
personal exclusions); everything else under `~/.config` is deliberately left out.

![Desktop](screenshots/desktop.png)

## Why COSMIC (not GNOME)

Greg first tried to make GNOME 50 tile like COSMIC via extensions, and hit
conflicting-extension issues plus a missing power button. Rather than keep
debugging that, he swapped desktops instead — COSMIC "installed and updated
cleanly," and all of GLB's terminal tooling (shell, prompt, Neovim/LazyVim) kept
working with no stops or errors straight through the switch.

## System

- **Fedora Linux 44 Workstation**, desktop environment swapped to COSMIC via
  Fedora's COSMIC Spin
- COSMIC desktop environment, `cosmic-comp` compositor, Wayland, same Dell E7450
  hardware (Intel HD Graphics 5500) as the [Milky Way rice](../milky-way/README.md)
- **Arch Linux + COSMIC** (installed via `archinstall`, `pacman`) — **applied and
  confirmed working 2026-09-21** on the same laptop after it was reinstalled from
  Fedora, using `./switch-rice.sh osaka-jade` and confirmed by screenshot. The
  wallpaper path (`~/Pictures/1-glowing-city.jpg`) resolved unchanged.

## What this rice looks like

**Wallpaper** — `cosmic/com.system76.CosmicBackground/v1/all`, points at
`~/Pictures/1-glowing-city.jpg`, a green/jade neon cyberpunk cityscape (Zoom
scaling, Lanczos filtering) — this is the "Osaka Jade" look the rice is named
for.

**Theme accent** — a jade/teal accent color (`#63D0DF`) set on the dark theme
(`cosmic/com.system76.CosmicTheme.Dark/v2/accent`), picking up the wallpaper's
palette. Otherwise stock COSMIC corner radii (`8` for most tiers, not squared off
like the Milky Way rice) — set via COSMIC Settings, not hand-edited.

**Icons/GTK theme** — stock **`Cosmic`** icon theme and **`adw-gtk3-dark`** GTK
theme (`gsettings`, not file-based so not tracked here). Unlike the Milky Way
rice, no extra icon/GTK theme package (e.g. Yaru) is required — this is a
lighter-touch rice that leans on COSMIC's own defaults plus the wallpaper/accent
color for its identity.

**Top panel — kept** (unlike the Milky Way rice, which removed it entirely):
`cosmic/com.system76.CosmicPanel.Panel/v1/`, size `XS`, fully opaque
(`opacity: 1.0`), anchored to the top.
- Center: clock
- Left wing: workspace-icons applet, clipboard manager applet
- Right wing: Tempest weather, status area, tiling toggle, audio, Bluetooth,
  network, battery, notifications, power/shutdown

**Dock — floating and auto-hiding**, closer to stock COSMIC than a custom layout:
`cosmic/com.system76.CosmicPanel.Dock/v1/`, `autohide: OnOverlap`, transparent
(`opacity: 0.0`), size `L`, rounded (`border_radius: 8`), `margin: 4`, does **not**
span the full width (`expand_to_edges: false`) and does **not** reserve screen
space (`exclusive_zone: false`) — windows can render underneath/behind it, unlike
the Milky Way rice's persistent full-width dock.
- Center: app launcher, workspace overview, pinned/running apps, app list

**Tiling** — `autotile: false` (`cosmic/com.system76.CosmicComp/v1/autotile`) —
floating windows, no forced tiling.

**Terminal** — Ghostty (per screenshots), with COSMIC Term's own font also set to
**JetBrainsMono Nerd Font Mono** (`cosmic/com.system76.CosmicTerm/v1/font_name`)
for consistency with GLB's terminal setups on this box.

## Packages required

None beyond COSMIC itself — this rice deliberately uses COSMIC's stock icon/GTK
theme rather than a third-party set like the Milky Way rice's Yaru. You do need
the extra panel/dock applets referenced above if you want the exact same
plugin set:

- `cosmic-ext-applet-workspace-icons` (`io.github.crocodile.cosmic-ext-applet-workspace-icons`)
- `cosmic-ext-applet-clipboard-manager` (`io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager`)
- `cosmic-ext-applet-tempest` (`com.vintagetechie.CosmicExtAppletTempest`) — weather

Exact package names/sources depend on distro; Fedora's COSMIC Spin already
bundles the core COSMIC applets, and these three extras are third-party COSMIC
applets typically installed via their own COPR/AUR/flatpak per-project
instructions (not verified here — check each applet's own repo for the current
install method on your distro).

## Trying this on your own machine

Requires COSMIC already running (confirmed on Fedora's COSMIC Spin; likely fine
on any distro that ships COSMIC).

1. **Back up your own config first** — this will overwrite files under
   `~/.config/cosmic/`:
   ```bash
   cp -r ~/.config/cosmic ~/.config/cosmic.bak
   ```
2. **Install the three extra applets** listed above, if you want the exact same
   panel/dock plugin set (optional — COSMIC will just skip missing plugin IDs).
3. **Clone this repo and copy its config in:**
   ```bash
   git clone https://github.com/ggregoro/Cosmic-Desktop-Customization.git /tmp/cosmic-setup
   cp -r /tmp/cosmic-setup/rices/osaka-jade/cosmic/. ~/.config/cosmic/
   ```
4. **Set the wallpaper.** The tracked config points at
   `/home/grego/Pictures/1-glowing-city.jpg` — that absolute path won't exist on
   your machine. Save your own copy of a similar green/jade cityscape image
   anywhere under your own `$HOME`, then edit the `source:` path in
   `~/.config/cosmic/com.system76.CosmicBackground/v1/all` to match.

COSMIC's settings daemon watches these config files live — most changes apply
within a second or two of a file being written, no reload or logout needed.

## Screenshots

- `screenshots/desktop.png` — the COSMIC desktop, dock, and top panel
- `screenshots/terminal-and-neovim.png` — Ghostty running GLB's `lt`/`lta` eza
  aliases, and LazyVim launching cleanly (confirms GLB's terminal tooling
  survived the GNOME→COSMIC switch intact)
- `screenshots/bashrc-and-files.png` — Ghostty + the COSMIC Files app, showing
  the `default` GLB profile's `.bashrc` aliases in place

## Restoring / reverting

- Full revert: `git checkout <this-rice's-first-commit> -- rices/osaka-jade/cosmic/`
  (see `git log -- rices/osaka-jade/` for the exact commit once this rice has more
  history)
- Or just switch back to the [Milky Way rice](../milky-way/README.md)'s config
  instead.
