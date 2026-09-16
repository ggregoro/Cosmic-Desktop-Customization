#!/usr/bin/env bash
# Switch this machine's live COSMIC config to one of the rices tracked in
# this repo. Meant for switching locally on Greg's own machine — for
# porting a rice to a different machine, see that rice's own README
# instead (paths there are written to be edited for someone else's $HOME).
#
# Usage: ./switch-rice.sh <rice-name>
#        ./switch-rice.sh --list

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICES_DIR="$REPO_DIR/rices"
COSMIC_DIR="$HOME/.config/cosmic"
BACKUP_DIR="$HOME/.config/cosmic-backups/$(date +%Y%m%d-%H%M%S)"

usage() {
    echo "Usage: $0 <rice-name>|--list"
    echo
    echo "Available rices:"
    for d in "$RICES_DIR"/*/; do
        echo "  - $(basename "$d")"
    done
}

if [[ $# -ne 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 1
fi

if [[ "$1" == "--list" ]]; then
    usage
    exit 0
fi

RICE="$1"
RICE_COSMIC_DIR="$RICES_DIR/$RICE/cosmic"

if [[ ! -d "$RICE_COSMIC_DIR" ]]; then
    echo "error: no rice named '$RICE' (looked for $RICE_COSMIC_DIR)" >&2
    usage
    exit 1
fi

echo "Backing up current config to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
cp -r "$COSMIC_DIR/." "$BACKUP_DIR/"

echo "Applying rice '$RICE' ..."
cp -r "$RICE_COSMIC_DIR/." "$COSMIC_DIR/"

# All three rices so far are dark-mode designs; harmless if a future
# light-mode rice is added, since that rice would just want this unset
# or flipped explicitly in its own README instead.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

echo "Restarting cosmic-panel and cosmic-bg so the new config actually renders ..."
pkill -x cosmic-panel || true
pkill -x cosmic-bg || true
sleep 2

echo "Done. Rice '$RICE' applied (previous config backed up to $BACKUP_DIR)."
echo "If the panel/wallpaper still look wrong, log out and back in."
