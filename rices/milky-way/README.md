# Milky Way

![Desktop](screenshots/desktop.png)

- **Wallpaper:** the Milky Way core.
- **Colors:** dark mode, blue accent (`#A1C0EB`), rounded corners, a thin
  border on the active window.
- **Panel and dock:** left as they are. The rice is made for the
  **One dock** layout (the screenshot shows an earlier version of it); add it with `--layout one-dock` or the picker's
  Layout menu (see [Panel layouts](../../README.md#panel-layouts-optional)).
- **Theme and icons:** [Yaru](https://github.com/ubuntu/yaru).
- **Windows:** tiling is on, one layout per workspace.
- **Terminal:** COSMIC Terminal fully opaque, in JetBrainsMono Nerd Font if
  it is installed.

Tested on Pop!_OS and Arch Linux. Not tested on Fedora.

## Extras

Install these before applying the rice. Anything you skip is left out and
the rest still applies.

**Yaru theme and icons**

```bash
# Pop!_OS
sudo apt install yaru-theme-gtk yaru-theme-icon

# Arch (from the AUR, so an AUR helper such as yay is needed)
yay -S yaru-gtk-theme yaru-icon-theme

# Fedora
sudo dnf install yaru-gtk3-theme yaru-icon-theme
```

## Install

From the repo folder (see the [main README](../../README.md#install) for the
full steps):

```bash
./switch-rice.sh milky-way
./switch-rice.sh milky-way --layout one-dock   # with its layout
```

## Uninstall

```bash
./switch-rice.sh --restore
```

To remove the extras as well:

```bash
# Pop!_OS
sudo apt remove yaru-theme-gtk yaru-theme-icon

# Arch
yay -R yaru-gtk-theme yaru-icon-theme

# Fedora
sudo dnf remove yaru-gtk3-theme yaru-icon-theme
```
