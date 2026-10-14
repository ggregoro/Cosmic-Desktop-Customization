# Osaka Jade

![Desktop](screenshots/desktop.png)

- **Wallpaper:** a green neon city at night.
- **Colors:** dark mode, jade accent (`#63D0DF`), COSMIC's standard rounded
  corners.
- **Panel and dock:** left as they are. The rice is made for the
  **Top bar + fixed dock** layout (the screenshot shows an earlier version of it); add it with `--layout top-bar-fixed-dock` or the picker's
  Layout menu (see [Panel layouts](../../README.md#panel-layouts-optional)).
- **Theme and icons:** COSMIC's own.
- **Windows:** floating (tiling is off).
- **Terminal:** COSMIC Terminal in JetBrainsMono Nerd Font if it is
  installed.

Tested on Pop!_OS, Fedora (COSMIC Spin) and Arch Linux.

## Extras

None needed.

## Install

From the repo folder (see the [main README](../../README.md#install) for the
full steps):

```bash
./switch-rice.sh osaka-jade
./switch-rice.sh osaka-jade --layout top-bar-fixed-dock   # with its layout
```

## Uninstall

```bash
./switch-rice.sh --restore
```
