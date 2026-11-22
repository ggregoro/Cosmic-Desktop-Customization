#!/usr/bin/env bash
# Apply one of the COSMIC rices in this repo to the current user's
# desktop, or undo the last one applied.
#
# Usage: ./switch-rice.sh <rice-name>   apply a rice
#        ./switch-rice.sh <rice-name> --layout <layout>
#                                       apply a rice and a panel layout
#        ./switch-rice.sh <rice-name> --frosted-off
#                                       apply a rice and switch off
#                                       frosted glass (lighter on older
#                                       hardware)
#        ./switch-rice.sh --layout <layout>
#                                       change only the panel layout
#        ./switch-rice.sh --list        list the rices and layouts
#        ./switch-rice.sh --restore     undo the most recent switch
#        ./switch-rice.sh --restore <backup-folder-name>

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICES_DIR="$REPO_DIR/rices"
LAYOUTS_DIR="$REPO_DIR/layouts"
COSMIC_DIR="$HOME/.config/cosmic"
BACKUPS_DIR="$HOME/.config/cosmic-backups"
WALLPAPER_DIR="$HOME/Pictures"
GSETTINGS_SCHEMA="org.gnome.desktop.interface"
GSETTINGS_KEYS=(color-scheme gtk-theme icon-theme)
# Name of the rice now applied, for the rice picker.
CURRENT_FILE="$BACKUPS_DIR/current-rice"
# Backups kept besides the oldest one, which holds your settings from
# before the first rice and is never removed.
KEEP_BACKUPS=10

usage() {
    echo "Usage: $0 <rice-name> [--layout <layout>] [--frosted-off]"
    echo "       $0 --layout <layout>"
    echo "       $0 --list"
    echo "       $0 --restore [backup-folder-name]"
    echo
    echo "Available rices:"
    for d in "$RICES_DIR"/*/; do
        echo "  - $(basename "$d")"
    done
    echo
    echo "--frosted-off switches off frosted glass (blur behind the panel, applets,"
    echo "launcher and windows), which is heavy on older graphics."
    echo
    echo "Panel layouts (without --layout, your panel and dock are left as they are):"
    for d in "$LAYOUTS_DIR"/*/; do
        echo "  - $(basename "$d")  ($(cat "$d/title"))"
    done
}

have() { command -v "$1" >/dev/null 2>&1; }

# cosmic-panel and cosmic-bg watch their config and redraw on their own,
# as they do for COSMIC Settings. Do not kill them: cosmic-session takes
# that for a crash and doubles its restart delay each time until logout
# (over a minute after a dozen switches), leaving the wallpaper grey.
restart_cosmic() {
    sleep 1
}

# Backup folders only (named by date and time), oldest first. Other
# folders under cosmic-backups, such as omarchy-keys, are not backups.
list_backups() {
    find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d \
        -name '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]' \
        2>/dev/null | sort
}

# Keep the oldest backup and the newest $KEEP_BACKUPS; remove the rest.
prune_backups() {
    local all=() i
    mapfile -t all < <(list_backups)
    (( ${#all[@]} > KEEP_BACKUPS + 1 )) || return 0
    for (( i = 1; i < ${#all[@]} - KEEP_BACKUPS; i++ )); do
        rm -rf -- "${all[$i]}"
    done
    echo "Removed $(( ${#all[@]} - KEEP_BACKUPS - 1 )) old backup(s); kept the first one and the newest $KEEP_BACKUPS."
}

theme_installed() {
    # $1 = theme name, $2 = "gtk" or "icon"
    local d
    if [[ "$2" == gtk ]]; then
        for d in "$HOME/.themes" "$HOME/.local/share/themes" /usr/share/themes; do
            [[ -d "$d/$1/gtk-3.0" ]] && return 0
        done
    else
        for d in "$HOME/.icons" "$HOME/.local/share/icons" /usr/share/icons; do
            [[ -d "$d/$1" ]] && return 0
        done
    fi
    return 1
}

is_opensuse() {
    [[ -r /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*suse' /etc/os-release
}

# Newer COSMIC Settings keep each look as a "theme bundle" and ship the
# built-in ones in /usr/share/cosmic. With them the wallpaper is read per
# mode (CosmicBackground.Dark/.Light), COSMIC apps take the icon theme from
# the theme itself, and Settings finds the active look by its name.
# COSMIC 1.11.0 has none of this and keeps the old path.
# RICE_BUNDLES=1 or 0 forces the choice.
has_theme_bundles() {
    case "${RICE_BUNDLES:-auto}" in
        1) return 0 ;;
        0) return 1 ;;
    esac
    compgen -G "/usr/share/cosmic/com.system76.CosmicThemeBundle.*" >/dev/null
}

# On newer COSMIC Settings, window border size, gaps and frosted glass are
# the user's own settings, so put back the values the rice just overwrote.
# Then install the rice as a theme in Settings > Appearance and switch it
# on, with its wallpaper. The files it adds go into applied-files, so
# --restore removes them again.
apply_bundles() {
    local rel
    if ! have python3; then
        echo "warning: python3 not found; the rice won't appear in Settings > Appearance and its wallpaper may not apply" >&2
        return 0
    fi
    while IFS= read -r rel; do
        if [[ -e "$BACKUP_DIR/cosmic/$rel" ]]; then
            cp "$BACKUP_DIR/cosmic/$rel" "$COSMIC_DIR/$rel"
        else
            rm -f "$COSMIC_DIR/$rel"
        fi
    done < <(cd "$RICE_COSMIC_DIR" && find . -path './com.system76.CosmicTheme.*' -type f \
                 \( -name active_hint -o -name gaps -o -name spacing -o -name 'frosted*' -o -name alpha_map \) \
                 | sed 's|^\./||')
    echo "Installing '$RICE' as a theme in Settings > Appearance ..."
    python3 "$REPO_DIR/build-bundles.py" --install "$RICE" >> "$BACKUP_DIR/applied-files"
    echo "note: if COSMIC Settings is open, close and reopen it to see the new theme."
}

# The bundle step writes the rice's icon theme without checking that it
# is installed. Put back the live value from before, and leave the name
# out of the rice's card in Settings so clicking it can't set it either.
undo_bundle_icons() {
    local rel
    while IFS= read -r rel; do
        case "$rel" in
            com.system76.CosmicThemeBundle.*/icon_theme)
                rm -f "$COSMIC_DIR/$rel" ;;
            com.system76.CosmicTheme.*/icon_theme)
                if [[ -e "$BACKUP_DIR/cosmic/$rel" ]]; then
                    cp "$BACKUP_DIR/cosmic/$rel" "$COSMIC_DIR/$rel"
                else
                    rm -f "$COSMIC_DIR/$rel"
                fi ;;
        esac
    done < "$BACKUP_DIR/applied-files"
}

# Switch off every part of frosted glass, in the theme and in the
# settings COSMIC Settings edits, for dark and light mode. The blur
# strength is left alone. The files go into applied-files, so --restore
# puts back what was there.
frosted_off() {
    local mode part key rel
    echo "Switching off frosted glass ..."
    for mode in Dark Light; do
        for part in "" .Builder; do
            for key in frosted_panel frosted_applets frosted_system_interface \
                       frosted_windows frosted_maximized_apps; do
                rel="com.system76.CosmicTheme.$mode$part/v2/$key"
                mkdir -p "$COSMIC_DIR/${rel%/*}"
                echo false > "$COSMIC_DIR/$rel"
                echo "$rel" >> "$BACKUP_DIR/applied-files"
            done
        done
    done
}

# openSUSE ships older panel applets (cosmic-applets 1.0.14 next to
# cosmic-panel 1.7.0 on Tumbleweed) that read the theme from v1, with
# colors as (red:, green:, blue:, alpha:) instead of "#RRGGBBAA". With
# only v2 written they fall back to the default cyan accent and round
# workspace buttons. Write a v1 copy of every v2 theme key the rice ships,
# with the colors converted, except keys the rice ships in v1 itself.
# Also add list_button, which the old loader needs to load the theme.
write_legacy_theme() {
    if ! have python3; then
        echo "warning: python3 not found; the panel applets may keep the default accent color" >&2
        return 0
    fi
    echo "Writing the theme for openSUSE's older panel applets ..."
    python3 -I - "$RICE_COSMIC_DIR" "$COSMIC_DIR" "$BACKUP_DIR/applied-files" <<'EOF'
import pathlib, re, sys
rice, cosmic, applied = (pathlib.Path(a) for a in sys.argv[1:])
hexcolor = re.compile(r'"#([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?"')

def to_v1(text):
    out = []
    for line in text.splitlines(keepends=True):
        ind = re.match(r'\s*', line).group(0)
        def conv(m):
            h, a = m.group(1), m.group(2) or "FF"
            vals = [int(x, 16) / 255 for x in (h[0:2], h[2:4], h[4:6], a)]
            i = ind + "    "
            body = "".join(f"{i}{k}: {v:.7f},\n" for k, v in zip(("red", "green", "blue", "alpha"), vals))
            return f"(\n{body}{ind})"
        out.append(hexcolor.sub(conv, line))
    return "".join(out)

written = []
for v2 in sorted(rice.glob("com.system76.CosmicTheme.*/v2")):
    comp = v2.parent.name
    dest = cosmic / comp / "v1"
    dest.mkdir(parents=True, exist_ok=True)
    for f in sorted(v2.iterdir()):
        if not f.is_file() or (rice / comp / "v1" / f.name).exists():
            continue
        (dest / f.name).write_text(to_v1(f.read_text()))
        written.append(f"{comp}/v1/{f.name}")
    if not comp.endswith(".Builder") and (dest / "button").exists() and not (rice / comp / "v1" / "list_button").exists():
        (dest / "list_button").write_text((dest / "button").read_text())
        written.append(f"{comp}/v1/list_button")
with applied.open("a") as fh:
    fh.writelines(w + "\n" for w in written)
EOF
}

panel_state() {
    cat "$COSMIC_DIR"/com.system76.CosmicPanel*/v1/* 2>/dev/null | md5sum
}

# cosmic-panel picks up a changed panel or dock by itself, but not always
# cleanly: Pop!_OS (COSMIC 1.10) keeps drawing a removed top bar, and Arch
# (COSMIC 1.9) has left an old bar next to the new one after an undo, until
# the next login. $1 = panel_state from before the change.
panel_note() {
    if [[ "$1" != "$(panel_state)" ]]; then
        echo "note: the panel changed. If the top bar or dock looks wrong (still there, missing or doubled), log out and back in."
    fi
}

restore() {
    local backup
    if [[ -n "${1:-}" ]]; then
        backup="$BACKUPS_DIR/$1"
    else
        backup="$(list_backups | tail -n 1)"
    fi
    if [[ -z "$backup" || ! -d "$backup/cosmic" ]]; then
        echo "error: no backup to restore (looked in $BACKUPS_DIR)" >&2
        exit 1
    fi

    echo "Restoring the config saved in $backup ..."
    local before
    before="$(panel_state)"
    # Files the rice added that did not exist before: remove them one by
    # one so COSMIC goes back to its default for each. Never remove the
    # whole directory while COSMIC is running.
    if [[ -f "$backup/applied-files" ]]; then
        while IFS= read -r rel; do
            [[ -e "$backup/cosmic/$rel" ]] || rm -f "$COSMIC_DIR/$rel"
        done < "$backup/applied-files"
        # A theme bundle the rice installed leaves empty folders behind.
        find "$COSMIC_DIR" -mindepth 1 -maxdepth 1 -type d -name 'com.system76.CosmicThemeBundle.*' \
            -exec find {} -depth -type d -empty -delete \;
    fi
    mkdir -p "$COSMIC_DIR"
    cp -r "$backup/cosmic/." "$COSMIC_DIR/"

    if have gsettings && [[ -f "$backup/gsettings" ]]; then
        while IFS='=' read -r key value; do
            [[ -n "$value" ]] || continue
            gsettings set "$GSETTINGS_SCHEMA" "$key" "$value" || true
        done < "$backup/gsettings"
    fi

    if [[ -s "$backup/previous-rice" ]]; then
        cp "$backup/previous-rice" "$CURRENT_FILE"
    else
        rm -f "$CURRENT_FILE"
    fi

    panel_note "$before"
    restart_cosmic
    echo "Done. Restored the config from $backup."
    echo "If the panel or wallpaper still look wrong, log out and back in."
}

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 1
fi

case "$1" in
    --list) usage; exit 0 ;;
    --restore) restore "${2:-}"; exit 0 ;;
esac

RICE=""
LAYOUT=""
FROSTED_OFF=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --layout)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            LAYOUT="$2"; shift 2 ;;
        --frosted-off) FROSTED_OFF=1; shift ;;
        -*) usage; exit 1 ;;
        *)  [[ -z "$RICE" ]] || { usage; exit 1; }
            RICE="$1"; shift ;;
    esac
done

RICE_DIR="$RICES_DIR/$RICE"
RICE_COSMIC_DIR="$RICE_DIR/cosmic"
LAYOUT_COSMIC_DIR="$LAYOUTS_DIR/$LAYOUT/cosmic"

if [[ -n "$FROSTED_OFF" && -z "$RICE" ]]; then
    echo "error: --frosted-off goes with a rice name" >&2
    usage
    exit 1
fi

if [[ -n "$RICE" && ! -d "$RICE_COSMIC_DIR" ]]; then
    echo "error: no rice named '$RICE' (looked for $RICE_COSMIC_DIR)" >&2
    usage
    exit 1
fi
if [[ -n "$LAYOUT" && ! -d "$LAYOUT_COSMIC_DIR" ]]; then
    echo "error: no layout named '$LAYOUT' (looked for $LAYOUT_COSMIC_DIR)" >&2
    usage
    exit 1
fi

if ! have cosmic-session; then
    echo "warning: COSMIC doesn't seem to be installed (no cosmic-session); copying the config anyway" >&2
fi

BACKUP_DIR="$BACKUPS_DIR/$(date +%Y%m%d-%H%M%S)"
echo "Backing up current config to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR/cosmic" "$COSMIC_DIR"
cp -r "$COSMIC_DIR/." "$BACKUP_DIR/cosmic/"
[[ -f "$CURRENT_FILE" ]] && cp "$CURRENT_FILE" "$BACKUP_DIR/previous-rice"
: > "$BACKUP_DIR/applied-files"
for d in ${RICE:+"$RICE_COSMIC_DIR"} ${LAYOUT:+"$LAYOUT_COSMIC_DIR"}; do
    (cd "$d" && find . -type f | sed 's|^\./||') >> "$BACKUP_DIR/applied-files"
done
[[ -z "$RICE" ]] || echo "com.system76.CosmicTheme.Mode/v1/is_dark" >> "$BACKUP_DIR/applied-files"
if have gsettings; then
    for key in "${GSETTINGS_KEYS[@]}"; do
        echo "$key=$(gsettings get "$GSETTINGS_SCHEMA" "$key" 2>/dev/null || true)"
    done > "$BACKUP_DIR/gsettings"
fi

applet_installed() {
    local d
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}" \
             "$HOME/.local/share/flatpak/exports/share" /var/lib/flatpak/exports/share \
             ${XDG_DATA_DIRS//:/ } /usr/local/share /usr/share; do
        [[ -f "$d/applications/$1.desktop" ]] && return 0
    done
    return 1
}

# Layouts can list add-on applets from the COSMIC Store, such as the
# clipboard manager. One that isn't installed is left out of the copied
# panel and dock. (com.system76 applets ship with COSMIC; some, like
# CosmicAppList, have no .desktop file, so they aren't checked.)
drop_missing_applets() {
    local f rel id missing=()
    while IFS= read -r f; do
        rel="${f#"$LAYOUT_COSMIC_DIR"/}"
        for id in $(grep -o '"[^"]*"' "$f" | tr -d '"'); do
            [[ "$id" == com.system76.* ]] && continue
            applet_installed "$id" && continue
            sed -i "/\"${id//./\\.}\"/d" "$COSMIC_DIR/$rel"
            [[ " ${missing[*]} " == *" $id "* ]] || missing+=("$id")
        done
    done < <(find "$LAYOUT_COSMIC_DIR" -type f -name 'plugins_*')
    for id in "${missing[@]}"; do
        echo "note: $id isn't installed, so it was left out. Install it from the COSMIC Store and apply the layout again to get it."
    done
}

apply_layout() {
    local before
    before="$(panel_state)"
    echo "Applying panel layout '$LAYOUT' ..."
    cp -r "$LAYOUT_COSMIC_DIR/." "$COSMIC_DIR/"
    drop_missing_applets
    panel_note "$before"
}

if [[ -z "$RICE" ]]; then
    apply_layout
    restart_cosmic
    prune_backups
    echo "Done. Panel layout '$LAYOUT' applied."
    echo "To undo it: $0 --restore"
    exit 0
fi

# The wallpaper ships with the rice. Copy it to ~/Pictures unless a file
# of that name is already there.
if [[ -d "$RICE_DIR/wallpaper" ]]; then
    mkdir -p "$WALLPAPER_DIR"
    for w in "$RICE_DIR/wallpaper"/*; do
        [[ -e "$WALLPAPER_DIR/$(basename "$w")" ]] || cp "$w" "$WALLPAPER_DIR/"
    done
fi

echo "Applying rice '$RICE' ..."
# Overlay, never replace: removing ~/.config/cosmic while COSMIC is
# running races its settings daemon. The icon theme is not copied: it is
# set further down, and only if it is installed.
(cd "$RICE_COSMIC_DIR" && find . -type f ! -path './com.system76.CosmicTk/v1/icon_theme' \
    -exec cp --parents -t "$COSMIC_DIR" {} +)

# The tracked wallpaper path uses __HOME__ in place of a real home folder.
BG_FILE="$COSMIC_DIR/com.system76.CosmicBackground/v1/all"
if [[ -f "$BG_FILE" ]]; then
    sed -i "s|__HOME__|$HOME|g" "$BG_FILE"
fi

is_opensuse && write_legacy_theme

has_theme_bundles && apply_bundles

# Every rice here is a dark-mode design.
mkdir -p "$COSMIC_DIR/com.system76.CosmicTheme.Mode/v1"
echo "true" > "$COSMIC_DIR/com.system76.CosmicTheme.Mode/v1/is_dark"

if have gsettings; then
    gsettings set "$GSETTINGS_SCHEMA" color-scheme 'prefer-dark' || true

    # GTK3 apps ignore color-scheme and only follow gtk-theme. A rice can
    # name its own theme in rices/<name>/gtk-theme; otherwise use
    # adw-gtk3-dark. Only set a theme that is installed: an unknown name
    # makes GTK3 fall back to light Adwaita.
    DEFAULT_GTK_THEME="adw-gtk3-dark"
    GTK_THEME_NAME="$DEFAULT_GTK_THEME"
    if [[ -f "$RICE_DIR/gtk-theme" ]]; then
        GTK_THEME_NAME="$(tr -d '[:space:]' < "$RICE_DIR/gtk-theme")"
    fi
    if [[ "$GTK_THEME_NAME" != "$DEFAULT_GTK_THEME" ]] && ! theme_installed "$GTK_THEME_NAME" gtk; then
        echo "warning: GTK theme '$GTK_THEME_NAME' isn't installed; using '$DEFAULT_GTK_THEME' instead" >&2
        GTK_THEME_NAME="$DEFAULT_GTK_THEME"
    fi
    if theme_installed "$GTK_THEME_NAME" gtk; then
        echo "Setting GTK theme to '$GTK_THEME_NAME' ..."
        gsettings set "$GSETTINGS_SCHEMA" gtk-theme "$GTK_THEME_NAME" || true
    else
        echo "warning: GTK theme '$GTK_THEME_NAME' isn't installed; leaving gtk-theme unchanged" >&2
    fi

    # Flatpak apps can't see host themes; they need the matching runtime.
    if have flatpak && ! flatpak info "org.gtk.Gtk3theme.$GTK_THEME_NAME" >/dev/null 2>&1; then
        echo "note: Flatpak GTK3 apps won't pick up '$GTK_THEME_NAME' until you run:" >&2
        echo "  flatpak install flathub org.gtk.Gtk3theme.$GTK_THEME_NAME" >&2
    fi

else
    echo "warning: gsettings not found; skipping the GTK dark mode and theme settings" >&2
fi

# Optional icon theme, named in rices/<name>/icon-theme. COSMIC apps read
# it from CosmicTk, GTK apps from gsettings. Only set a theme that is
# installed: an unknown name leaves COSMIC with missing icons.
if [[ -f "$RICE_DIR/icon-theme" ]]; then
    ICON_THEME_NAME="$(tr -d '[:space:]' < "$RICE_DIR/icon-theme")"
    if theme_installed "$ICON_THEME_NAME" icon; then
        echo "Setting icon theme to '$ICON_THEME_NAME' ..."
        mkdir -p "$COSMIC_DIR/com.system76.CosmicTk/v1"
        echo "\"$ICON_THEME_NAME\"" > "$COSMIC_DIR/com.system76.CosmicTk/v1/icon_theme"
        echo "com.system76.CosmicTk/v1/icon_theme" >> "$BACKUP_DIR/applied-files"
        if have gsettings; then
            gsettings set "$GSETTINGS_SCHEMA" icon-theme "$ICON_THEME_NAME" || true
        fi
    else
        echo "warning: icon theme '$ICON_THEME_NAME' isn't installed; leaving the icon theme unchanged" >&2
        undo_bundle_icons
    fi
fi

[[ -z "$FROSTED_OFF" ]] || frosted_off

[[ -z "$LAYOUT" ]] || apply_layout

echo "$RICE" > "$CURRENT_FILE"

restart_cosmic
prune_backups

echo "Done. Rice '$RICE' applied${LAYOUT:+ with panel layout '$LAYOUT'}."
echo "To undo it: $0 --restore"
echo "If the panel or wallpaper still look wrong, log out and back in."
