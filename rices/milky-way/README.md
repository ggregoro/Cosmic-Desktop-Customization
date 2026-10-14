# Milky Way

![Desktop](screenshots/desktop.png)

- **Wallpaper:** the Milky Way core.
- **Colors:** dark mode, blue accent (`#A1C0EB`), rounded corners, a thin
  border on the active window.
- **Panel and dock:** a half-transparent dock across the full width of the
  bottom edge; your applets stay where they are. In the screenshot the top
  panel is gone and the dock holds everything (see
  [Original panel layout](#original-panel-layout-optional)).
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

**Panel applets** (weather, clipboard manager, workspace icons), only needed
for the [original panel layout](#original-panel-layout-optional), from
Flathub on any distro:

```bash
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub com.vintagetechie.CosmicExtAppletTempest
flatpak install --user flathub io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager
flatpak install --user flathub io.github.crocodile.cosmic-ext-applet-workspace-icons
```

On Arch, install Flatpak first with `sudo pacman -S flatpak`.

## Original panel layout (optional)

The rice changes how your panel and dock look, but it leaves your applets
where they are. To get the layout shown in the screenshot as well (no top panel, and everything in one dock across the bottom),
install the applets above first, then run this from the repo folder:

```bash
cp -r rices/milky-way/panel-layout/. ~/.config/cosmic/
pkill -x cosmic-panel
```

This replaces the applets on your panel and dock. `./switch-rice.sh --restore`
puts your own back, as long as you have not switched rices since.

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
