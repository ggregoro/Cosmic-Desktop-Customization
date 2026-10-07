#!/usr/bin/env bash
# Apply one of the COSMIC rices in this repo to the current user's
# desktop, or undo the last one applied.
#
# Usage: ./switch-rice.sh <rice-name>   apply a rice
#        ./switch-rice.sh --list        list the rices
#        ./switch-rice.sh --restore     undo the most recent switch
#        ./switch-rice.sh --restore <backup-folder-name>

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICES_DIR="$REPO_DIR/rices"
COSMIC_DIR="$HOME/.config/cosmic"
BACKUPS_DIR="$HOME/.config/cosmic-backups"
WALLPAPER_DIR="$HOME/Pictures"
GSETTINGS_SCHEMA="org.gnome.desktop.interface"
GSETTINGS_KEYS=(color-scheme gtk-theme icon-theme)

usage() {
    echo "Usage: $0 <rice-name>"
    echo "       $0 --list"
    echo "       $0 --restore [backup-folder-name]"
    echo
    echo "Available rices:"
    for d in "$RICES_DIR"/*/; do
        echo "  - $(basename "$d")"
    done
}

have() { command -v "$1" >/dev/null 2>&1; }

# cosmic-session restarts both within about a second, and the new
# processes read the config that is on disk now.
restart_cosmic() {
    echo "Restarting cosmic-panel and cosmic-bg ..."
    pkill -x cosmic-panel || true
    pkill -x cosmic-bg || true
    sleep 2
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

restore() {
    local backup
    if [[ -n "${1:-}" ]]; then
        backup="$BACKUPS_DIR/$1"
    else
        backup="$(find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)"
    fi
    if [[ -z "$backup" || ! -d "$backup/cosmic" ]]; then
        echo "error: no backup to restore (looked in $BACKUPS_DIR)" >&2
        exit 1
    fi

    echo "Restoring the config saved in $backup ..."
    # Files the rice added that did not exist before: remove them one by
    # one so COSMIC goes back to its default for each. Never remove the
    # whole directory while COSMIC is running.
    if [[ -f "$backup/applied-files" ]]; then
        while IFS= read -r rel; do
            [[ -e "$backup/cosmic/$rel" ]] || rm -f "$COSMIC_DIR/$rel"
        done < "$backup/applied-files"
    fi
    mkdir -p "$COSMIC_DIR"
    cp -r "$backup/cosmic/." "$COSMIC_DIR/"

    if have gsettings && [[ -f "$backup/gsettings" ]]; then
        while IFS='=' read -r key value; do
            [[ -n "$value" ]] || continue
            gsettings set "$GSETTINGS_SCHEMA" "$key" "$value" || true
        done < "$backup/gsettings"
    fi

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

RICE="$1"
RICE_DIR="$RICES_DIR/$RICE"
RICE_COSMIC_DIR="$RICE_DIR/cosmic"

if [[ ! -d "$RICE_COSMIC_DIR" ]]; then
    echo "error: no rice named '$RICE' (looked for $RICE_COSMIC_DIR)" >&2
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
(cd "$RICE_COSMIC_DIR" && find . -type f | sed 's|^\./||') > "$BACKUP_DIR/applied-files"
echo "com.system76.CosmicTheme.Mode/v1/is_dark" >> "$BACKUP_DIR/applied-files"
if have gsettings; then
    for key in "${GSETTINGS_KEYS[@]}"; do
        echo "$key=$(gsettings get "$GSETTINGS_SCHEMA" "$key" 2>/dev/null || true)"
    done > "$BACKUP_DIR/gsettings"
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
# running races its settings daemon.
cp -r "$RICE_COSMIC_DIR/." "$COSMIC_DIR/"

# The tracked wallpaper path uses __HOME__ in place of a real home folder.
BG_FILE="$COSMIC_DIR/com.system76.CosmicBackground/v1/all"
if [[ -f "$BG_FILE" ]]; then
    sed -i "s|__HOME__|$HOME|g" "$BG_FILE"
fi

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

    # Optional icon theme, named in rices/<name>/icon-theme.
    if [[ -f "$RICE_DIR/icon-theme" ]]; then
        ICON_THEME_NAME="$(tr -d '[:space:]' < "$RICE_DIR/icon-theme")"
        if theme_installed "$ICON_THEME_NAME" icon; then
            echo "Setting icon theme to '$ICON_THEME_NAME' ..."
            gsettings set "$GSETTINGS_SCHEMA" icon-theme "$ICON_THEME_NAME" || true
        else
            echo "warning: icon theme '$ICON_THEME_NAME' isn't installed; leaving icon-theme unchanged" >&2
        fi
    fi
else
    echo "warning: gsettings not found; skipping the GTK dark mode, theme and icon settings" >&2
fi

restart_cosmic

echo "Done. Rice '$RICE' applied."
echo "To undo it: $0 --restore"
echo "If the panel or wallpaper still look wrong, log out and back in."
