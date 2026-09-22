# Milky Way rice

One of several rices in this repo — see the [top-level README](../../README.md) for
the full list. Tracked configuration for a redesigned
[COSMIC](https://system76.com/cosmic) desktop. Originally built on Pop!_OS/apt;
reapplied and confirmed working on Arch Linux/pacman (2026-08-18) after the same
laptop was reinstalled. This directory is a subset of `~/.config` — only the
`cosmic/` directory here (i.e. this rice's own `rices/milky-way/cosmic/`, referred
to below as just `cosmic/`) is tracked (see `../../.gitignore`); everything else
under `~/.config` (browser profiles, app caches, unrelated app settings) is
deliberately left out.

![Final desktop](screenshots/final-desktop.png)

## System

Confirmed working on:

- **Pop!_OS 24.04 LTS**, `apt` — original build
- **Arch Linux**, `pacman` + an AUR helper (e.g. [`yay`](https://github.com/Jguer/yay)) —
  reapplied 2026-08-18 on the same laptop after a reinstall

Either way: COSMIC desktop environment, `cosmic-comp` compositor, Wayland, Intel HD
Graphics 5500 (`i915`).

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

- Left wing: app launcher, workspace overview, pinned/running apps, window minimize
- Center: workspace-icons applet (per-workspace app icon overview)
- Right wing, in order: weather (Tempest applet), clipboard manager, tiling toggle,
  volume, Bluetooth, status area (tray icons for background/legacy apps), network,
  battery, notifications, clock, power/shutdown
- Persistent (`autohide: Never`) and reserves screen space (`exclusive_zone: true`)
  so windows never render underneath it
- Spans the full width of the screen (`expand_to_edges: true`), flush against the
  bottom edge (`anchor_gap: false`, `margin: 0`), square dock corners
  (`border_radius: 0`)
- Size `S`, `padding: 4`, `opacity: 0.5` — a half-transparent, moderately-sized dock
  (updated 2026-09-21 from the original size-`XS`/fully-opaque/no-padding look; the
  applet set was also expanded this same update to carry over a status-area tray
  icon and notifications applet that had drifted into daily use on the panel before
  this rice was reapplied)

**Appearance style** — set via COSMIC Settings' Desktop > Appearance > Style panel
(not hand-edited): moderately rounded corners (`corner_radii`, S/M/L/XL tiers at
`8.0`, XS tier unchanged at `2.0`), a slightly wider tiling gap (`gaps`, `(0, 5)`),
and a thinner active-window focus border (`active_hint: 1`, down from COSMIC's
default `2`) — tracked under `cosmic/com.system76.CosmicTheme.{Dark,Light}{,.Builder}/`.
Updated 2026-09-21 from the original square-corners (`2.0` on every tier)/tighter-gap
(`(0, 3)`)/default-focus-border (`2`) look.

**Terminal** — `cosmic/com.system76.CosmicTerm/v1/opacity` set to `100` (fully
opaque; COSMIC's terminal defaults to a slightly transparent background). Updated
2026-09-21 from `80`.

## Packages required

| Distro | Package | Reason | Source |
|---|---|---|---|
| Pop!_OS/Ubuntu-based (`apt`) | `yaru-theme-gtk` | Yaru GTK theme | official repos, no PPA needed |
| Pop!_OS/Ubuntu-based (`apt`) | `yaru-theme-icon` | Yaru icon set | official repos, no PPA needed |
| Arch (`pacman`) | `yaru-gtk-theme` | Yaru GTK theme | **AUR** — not in the official repos |
| Arch (`pacman`) | `yaru-icon-theme` | Yaru icon set | **AUR** — not in the official repos |

```bash
# apt (Pop!_OS/Ubuntu-based)
sudo apt install yaru-theme-gtk yaru-theme-icon

# pacman + an AUR helper (Arch)
yay -S yaru-gtk-theme yaru-icon-theme
```

After installing, the GTK/icon theme still needs to be selected (not tracked here,
since it's `dconf` state, not a file) — same command on either distro:

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
```

## Trying this on your own machine

Requires COSMIC already running — confirmed on Pop!_OS and Arch Linux (see
"System" above), likely fine on any distro that ships it.

1. **Back up your own config first** — this will overwrite files under
   `~/.config/cosmic/`:
   ```bash
   cp -r ~/.config/cosmic ~/.config/cosmic.bak
   ```
2. **Install the theme packages** — see "Packages required" above for the exact
   names per distro:
   ```bash
   # apt (Pop!_OS/Ubuntu-based)
   sudo apt install yaru-theme-gtk yaru-theme-icon

   # pacman + an AUR helper (Arch) — these are AUR-only, not in the official repos
   yay -S yaru-gtk-theme yaru-icon-theme
   ```
3. **Clone this repo and copy its config in:**
   ```bash
   git clone https://github.com/ggregoro/Cosmic-Desktop-Customization.git /tmp/cosmic-setup
   cp -r /tmp/cosmic-setup/rices/milky-way/cosmic/. ~/.config/cosmic/
   ```
4. **Select the Yaru theme/icons** (not a file, so cloning alone won't set it):
   ```bash
   gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
   gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
   ```
5. **Set the wallpaper.** The tracked config points at
   `/home/grego/Pictures/milky-way-core-jeremy-thomas-unsplash.jpg` — that
   absolute path won't exist on your machine. Download the image from
   [Jeremy Thomas on Unsplash](https://unsplash.com/photos/blue-and-purple-galaxy-digital-wallpaper-E0AHdsENmDg),
   save it anywhere under your own `$HOME`, then edit the `source:` path in
   `~/.config/cosmic/com.system76.CosmicBackground/v1/all` to match.

COSMIC's settings daemon watches these files live, so changes should appear
within a second or two — no reload or logout needed.

## Restoring / reverting

- `git log` shows the full history from `pre-claude-baseline` (the state of
  `~/.config/cosmic` before this project started) through every change since.
- Full revert: `git checkout pre-claude-baseline -- cosmic/ && rm -rf rices/milky-way/cosmic && mv cosmic rices/milky-way/cosmic`
  (the tag predates the move to `rices/milky-way/cosmic/`, so its `cosmic/` path
  has to replace the current one after checkout, not sit alongside it)
- Package removal:
  ```bash
  sudo apt remove yaru-theme-gtk yaru-theme-icon   # apt (Pop!_OS/Ubuntu-based)
  yay -R yaru-gtk-theme yaru-icon-theme             # pacman + AUR helper (Arch)
  ```

COSMIC's settings daemon watches these config files live — most changes apply
within a second or two of a file being written, no reload or logout needed.
