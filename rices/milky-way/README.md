# Milky Way

![Desktop](screenshots/desktop.png)

- **Wallpaper:** the Milky Way core.
- **Colors:** dark mode, blue accent (`#A1C0EB`), rounded corners, a thin
  border on the active window.
- **Layout:** no top panel. One half-transparent dock across the full width
  of the bottom edge holds everything: launcher, workspaces and pinned apps
  on the left, workspace icons in the center, and weather, clipboard,
  tiling, sound, Bluetooth, tray, network, battery, notifications, clock and
  power on the right.
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

**Panel applets** (weather, clipboard manager, workspace icons), from
Flathub on any distro:

```bash
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub com.vintagetechie.CosmicExtAppletTempest
flatpak install --user flathub io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager
flatpak install --user flathub io.github.crocodile.cosmic-ext-applet-workspace-icons
```

On Arch, install Flatpak first with `sudo pacman -S flatpak`.

## Install

From the repo folder (see the [main README](../../README.md#install) for the
full steps):

```bash
./switch-rice.sh milky-way
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

```bash
flatpak uninstall --user com.vintagetechie.CosmicExtAppletTempest
flatpak uninstall --user io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager
flatpak uninstall --user io.github.crocodile.cosmic-ext-applet-workspace-icons
```
