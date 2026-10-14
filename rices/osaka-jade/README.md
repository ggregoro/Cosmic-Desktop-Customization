# Osaka Jade

![Desktop](screenshots/desktop.png)

- **Wallpaper:** a green neon city at night.
- **Colors:** dark mode, jade accent (`#63D0DF`), COSMIC's standard rounded
  corners.
- **Panel and dock:** a slim top panel, and a floating, transparent dock
  at the bottom that hides when a window overlaps it. Your applets stay
  where they are (see
  [Original panel layout](#original-panel-layout-optional) for the one in
  the screenshot).
- **Theme and icons:** COSMIC's own.
- **Windows:** floating (tiling is off).
- **Terminal:** COSMIC Terminal in JetBrainsMono Nerd Font if it is
  installed.

Tested on Pop!_OS, Fedora (COSMIC Spin) and Arch Linux.

## Extras

**Panel applets** (weather, clipboard manager, workspace icons), only needed
for the [original panel layout](#original-panel-layout-optional), from
Flathub on any distro. Any you skip is left out of the panel.

```bash
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub com.vintagetechie.CosmicExtAppletTempest
flatpak install --user flathub io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager
flatpak install --user flathub io.github.crocodile.cosmic-ext-applet-workspace-icons
```

On Arch, install Flatpak first with `sudo pacman -S flatpak`.

## Original panel layout (optional)

The rice changes how your panel and dock look, but it leaves your applets
where they are. To get the layout shown in the screenshot as well (workspace icons and clipboard on the left of the top panel, the clock in the center, weather and the system applets on the right, launcher and pinned apps in the dock),
install the applets above first, then run this from the repo folder:

```bash
cp -r rices/osaka-jade/panel-layout/. ~/.config/cosmic/
pkill -x cosmic-panel
```

This replaces the applets on your panel and dock. `./switch-rice.sh --restore`
puts your own back, as long as you have not switched rices since.

## Install

From the repo folder (see the [main README](../../README.md#install) for the
full steps):

```bash
./switch-rice.sh osaka-jade
```

## Uninstall

```bash
./switch-rice.sh --restore
```

To remove the applets as well:

```bash
flatpak uninstall --user com.vintagetechie.CosmicExtAppletTempest
flatpak uninstall --user io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager
flatpak uninstall --user io.github.crocodile.cosmic-ext-applet-workspace-icons
```
