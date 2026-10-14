# Downtown

![Desktop](screenshots/desktop.png)

- **Wallpaper:** a figure on a rooftop over a neon city at night, pink-red
  and gold signs and cyan light beams. It is ultra-wide (3840 x 1633), so
  on a 16:9 screen the sides are cropped and the middle is kept.
- **Colors:** dark mode, near-black background (`#07070C`), warm grey-white
  text, lavender-blue accent (`#7A77BA`); warnings in the gold of the
  tower sign (`#F5B13B`), errors in the pink-red of the signs
  (`#FF3D6E`). The palette comes from the
  [Downtown](https://github.com/ggregoro/downtown) Omarchy theme.
- **Corners:** square, on windows and controls.
- **Icons:** Yaru in its purple, dark-mode version (`Yaru-purple-dark`),
  so folders match the lavender accent. Needs Yaru installed (see
  below); without it your icons stay as they are.
- **Terminal:** COSMIC Terminal at 90% opacity.
- **Layout:** unchanged. This rice sets colors, corners, wallpaper, icons
  and terminal opacity only, so your panel and dock stay as they are.

The color shades were worked out by script from the palette, not
produced by COSMIC. To have COSMIC work them out itself, open Settings >
Desktop > Appearance after applying and pick the accent color once.

Tested on Arch Linux. On Pop!_OS the accent color, square corners and
wallpaper did not apply in the first test; that is being looked into.
Not yet tested on Fedora. The terminal colors import has not been tried
yet.

The wallpaper is busy along the bottom edge, so dock icons can be hard
to see over it. The rice leaves the dock alone, but raising the dock's
opacity helps: the screenshot above uses 75%, set in Settings >
Desktop > Dock > Background opacity.

The wallpaper was found on WallpaperSafari; its artist is unknown. If it
is yours, open an issue and it will be credited or removed, as you
prefer.

## Extras

**Terminal colors** (optional). The rice does not change COSMIC
Terminal's text colors. To use the Downtown ones, open COSMIC
Terminal, choose View > Color schemes > Import, and pick
`rices/downtown/extras/downtown-terminal.ron`. Then select
"Downtown" in the list.

## Install

**Yaru icons** (for the purple folders):

```bash
# Pop!_OS
sudo apt install yaru-theme-icon

# Arch (from the AUR, so an AUR helper such as yay is needed)
yay -S yaru-icon-theme

# Fedora
sudo dnf install yaru-icon-theme
```

Then, from the repo folder (see the [main README](../../README.md#install) for the
full steps):

```bash
./switch-rice.sh downtown
```

## Uninstall

```bash
./switch-rice.sh --restore
```
