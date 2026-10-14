# Cosmic Desktop Customization

Six ready-made looks ("rices") for the [COSMIC](https://system76.com/cosmic)
desktop, and one script that installs or removes any of them.

| Milky Way | Osaka Jade | Onyx | Glowing City | Violet Tide | Downtown |
|---|---|---|---|---|---|
| ![Milky Way desktop](rices/milky-way/screenshots/desktop.png) | ![Osaka Jade desktop](rices/osaka-jade/screenshots/desktop.png) | ![Onyx desktop](rices/onyx/screenshots/desktop.png) | ![Glowing City desktop](rices/glowing-city/screenshots/desktop.png) | ![Violet Tide desktop](rices/violet-tide/screenshots/desktop.png) | ![Downtown desktop](rices/downtown/screenshots/desktop.png) |

| Rice | Look | Changes |
|---|---|---|
| [`milky-way`](rices/milky-way/README.md) | Milky Way wallpaper, blue accent, a half-transparent dock across the full width, Yaru theme and icons | Colors, wallpaper, panel and dock look |
| [`osaka-jade`](rices/osaka-jade/README.md) | Green neon city wallpaper, jade accent, slim top panel plus a floating dock that hides itself | Colors, wallpaper, panel and dock look |
| [`onyx`](rices/onyx/README.md) | Pure black with grey accents, dark street wallpaper | Colors and wallpaper only |
| [`glowing-city`](rices/glowing-city/README.md) | Pure black with grey accents, blue neon city wallpaper | Colors and wallpaper only |
| [`violet-tide`](rices/violet-tide/README.md) | Dark slate-purple with a pink-lavender accent, purple sunset-over-water wallpaper, square corners, see-through terminal | Colors, corners, wallpaper and terminal opacity |
| [`downtown`](rices/downtown/README.md) | Near-black with a lavender-blue accent, neon city at night wallpaper, pink-red and gold warnings, square corners | Colors, corners, wallpaper and terminal opacity |

## Requirements

- A working COSMIC desktop on Pop!_OS, Arch Linux or Fedora (COSMIC Spin).
  Any other distro that uses `apt`, `pacman` or `dnf` should work the same
  way.
- `git`, to download this repo.

| Rice | Pop!_OS (`apt`) | Arch (`pacman`) | Fedora (`dnf`) |
|---|---|---|---|
| `milky-way` | tested | tested | not tested |
| `osaka-jade` | tested | tested | tested |
| `onyx` | tested | tested | tested |
| `glowing-city` | tested | tested | not tested |
| `violet-tide` | tested | tested | tested |
| `downtown` | tested | tested | tested |

## Install

### 1. Get the repo

```bash
# Pop!_OS
sudo apt install git

# Arch
sudo pacman -S git

# Fedora
sudo dnf install git
```

```bash
git clone https://github.com/ggregoro/Cosmic-Desktop-Customization.git
cd Cosmic-Desktop-Customization
```

### 2. Install the dark GTK theme (optional)

Older GTK3 apps ignore COSMIC's dark mode and stay light unless the
`adw-gtk3-dark` theme is installed. The rice still applies without it.

```bash
# Arch
sudo pacman -S adw-gtk-theme

# Fedora
sudo dnf install adw-gtk3-theme
```

Pop!_OS has no `apt` package for it. Download the latest `adw-gtk3v*.tar.xz`
from the [adw-gtk3 releases page](https://github.com/lassekongo83/adw-gtk3/releases)
and unpack it into your themes folder:

```bash
mkdir -p ~/.local/share/themes
tar -xf ~/Downloads/adw-gtk3v*.tar.xz -C ~/.local/share/themes
```

GTK3 apps installed as Flatpaks need the Flatpak copy of the theme as well
(any distro):

```bash
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark
```

### 3. Install the extras your rice needs

`milky-way` also uses the Yaru theme, and `milky-way` and `osaka-jade`
suggest three optional panel applets. The commands are in each rice's own README:
[`milky-way`](rices/milky-way/README.md#extras),
[`osaka-jade`](rices/osaka-jade/README.md#extras).
`onyx` and `glowing-city` need nothing extra.
[`violet-tide`](rices/violet-tide/README.md#extras) and
[`downtown`](rices/downtown/README.md#extras) have optional terminal
colors to import by hand.

### 4. Apply the rice

```bash
./switch-rice.sh --list
./switch-rice.sh osaka-jade
```

The script:

1. Saves your current COSMIC settings to a dated folder under
   `~/.config/cosmic-backups/`.
2. Copies the rice's wallpaper to `~/Pictures`.
3. Copies the rice's settings into `~/.config/cosmic`.
4. Turns on dark mode and sets the GTK theme (and the icon theme, for
   `milky-way` and `downtown`).
5. Restarts the panel and the wallpaper so the change shows at once.
   Usually no logout is needed, but on Pop!_OS and Fedora some settings
   (such as the accent color, corners or icons) may only show after
   logging out and back in.

Run it again with another name to switch rices. No rice changes which
applets are on your panel and dock. `milky-way` and `osaka-jade` change how
the panel and dock look (size, transparency, corners, hiding); the other
four leave them as they are.

## Uninstall

Put back the settings you had before the last switch:

```bash
./switch-rice.sh --restore
```

Each switch makes its own backup. The script keeps the oldest one, which
holds your settings from before the first rice, and the newest 10; older
ones in between are removed. To go back further, name the backup folder:

```bash
ls ~/.config/cosmic-backups
./switch-rice.sh --restore 20260101-120000
```

The restore puts back your COSMIC settings, dark-mode setting, GTK theme and
icon theme. It leaves the wallpaper images in `~/Pictures` and any packages
you installed; remove those yourself if you no longer want them. Package
removal commands are in each rice's README.

## Rice picker (optional)

A window for choosing a rice, like Omarchy's theme menu: the rices are
shown as cards with a screenshot; pick one to see it large with what it
changes, then Apply. "Undo last switch" goes back to the settings from
before the last switch (`./switch-rice.sh --restore`). Keys: arrows to
move, Enter to apply, Esc to close.

It needs GTK 4 for Python:

```bash
# Pop!_OS
sudo apt install python3-gi gir1.2-gtk-4.0

# Arch
sudo pacman -S python-gobject gtk4

# Fedora
sudo dnf install python3-gobject gtk4
```

Then, from the repo folder:

```bash
./rice-picker.py --install    # adds Rice Picker to the app list
./omarchy-keys.sh --apply     # optional: opens it with Super+Shift+Ctrl+Space
./rice-picker.py --remove     # takes it out of the app list again
```

`--install` links `~/.local/bin/rice-picker` to this repo, so keep the
repo where it is (or run `--install` again after moving it). The
screenshots are previews: on Pop!_OS and Fedora some parts only show
after logging out and back in, and the picker reminds you.

Tried so far only outside COSMIC; not yet tested on a COSMIC desktop.

## Omarchy-style keys (optional)

If you also use Omarchy, these add a few of its shortcuts to COSMIC so
the same keys work on both. They work with any rice, or none.

| Key | Opens |
|---|---|
| `Super+Return` | Terminal |
| `Super+Shift+Return` | Web browser |
| `Super+Shift+B` | Web browser |
| `Super+Shift+F` | File manager |
| `Super+Shift+Ctrl+Space` | Rice picker (see below; install it first) |

COSMIC does not use any of these keys, so none of its own shortcuts
change: `Super+T`, `Super+B` and `Super+F` still work as before.

```bash
./omarchy-keys.sh --apply     # add them
./omarchy-keys.sh --remove    # take them away again
```

Any shortcuts you set yourself are kept. If you already use one of
these keys for something else, the script changes nothing and
tells you. `--remove` puts your shortcuts file back as it was, unless
you changed shortcuts in Settings since; then remove the keys there by
hand. If you added the keys before the rice picker key existed,
run `--apply` again to add it. The rice switch and its `--restore` do not touch these
keys. If a key does nothing at first, log out and back in.

Tested on Pop!_OS (with a shortcut of its own already set).

## Troubleshooting

**The panel, dock or wallpaper still shows the old look.** Restart them:

```bash
pkill -x cosmic-panel
pkill -x cosmic-bg
```

COSMIC starts both again within a second. If that does not help, or if only
the window borders are wrong, log out and back in.

**The window border is a different color from the accent.** Every rice
clears a saved window border color so the border follows the accent;
log out and back in for it to show. `--restore` brings your old border
color back.

**A panel applet is missing.** If you used a rice's original panel
layout (see its README), it lists an applet that is not installed. Install
it (see the rice's README) and restart the panel as above.

**Do not delete or move `~/.config/cosmic` while COSMIC is running.** COSMIC
rewrites the folder as you remove it and the result is a mix of old and
default settings. Use `./switch-rice.sh --restore`, which copies files back
in place.

## Wallpaper credits

- `milky-way`: photo by
  [Jeremy Thomas on Unsplash](https://unsplash.com/photos/blue-and-purple-galaxy-digital-wallpaper-E0AHdsENmDg)
  (Unsplash License).
- `osaka-jade`: from the Osaka Jade theme in
  [Omarchy](https://github.com/omacom/omarchy) (MIT License).
- `onyx`: from the [Onyx](https://github.com/ggregoro/onyx) theme.
- `glowing-city`: a blue-tinted edit of the `osaka-jade` wallpaper.
- `violet-tide`: four photos from Unsplash (Unsplash License), by Engin
  Yapici, Artiom Vallat, Loris Boulinguez and Vishnu K R.
- `downtown`: found on WallpaperSafari, artist unknown. If it is yours,
  open an issue and it will be credited or removed, as you prefer.
