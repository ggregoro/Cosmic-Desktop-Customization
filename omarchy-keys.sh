#!/usr/bin/env bash
# Add a few Omarchy-style keyboard shortcuts to COSMIC, or take them
# away again. Only keys COSMIC does not already use are added, so no
# COSMIC shortcut changes:
#   Super+Return         terminal
#   Super+Shift+Return   web browser
#   Super+Shift+B        web browser
#   Super+Shift+F        file manager
#
# Usage: ./omarchy-keys.sh --apply    add the shortcuts
#        ./omarchy-keys.sh --remove   take them away again

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_FILE="$REPO_DIR/keys/omarchy.ron"
CUSTOM_DIR="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
CUSTOM_FILE="$CUSTOM_DIR/custom"
# Kept outside ~/.config/cosmic so COSMIC never reads them.
STATE_DIR="$HOME/.config/cosmic-backups/omarchy-keys"
BEFORE_FILE="$STATE_DIR/custom.before"
AFTER_FILE="$STATE_DIR/custom.applied"
NONE_MARK="$STATE_DIR/no-custom-file-before"

# The shortcuts in keys/omarchy.ron, as COSMIC writes them once spaces,
# line breaks and trailing commas are dropped.
KEY_PATTERNS=(
    'modifiers:[Super],key:"Return"'
    'modifiers:[Super,Shift],key:"Return"'
    'modifiers:[Super,Shift],key:"b"'
    'modifiers:[Super,Shift],key:"f"'
)
KEY_NAMES=(Super+Return Super+Shift+Return Super+Shift+B Super+Shift+F)

usage() {
    echo "Usage: $0 --apply"
    echo "       $0 --remove"
}

# Print a file with spaces, line breaks and trailing commas removed, so
# the same shortcut matches however it was laid out.
squash() {
    tr -d '[:space:]' < "$1" | sed 's/,\]/]/g; s/,)/)/g'
}

# True when the file holds no shortcuts: missing, empty, or just "{}".
no_custom_shortcuts() {
    [[ ! -s "$CUSTOM_FILE" ]] && return 0
    [[ -z "$(tr -d '[:space:]{}' < "$CUSTOM_FILE")" ]]
}

apply() {
    if [[ -f "$AFTER_FILE" ]] && cmp -s "$AFTER_FILE" "$CUSTOM_FILE"; then
        echo "The Omarchy-style shortcuts are already on. Nothing to do."
        return
    fi

    local squashed i clash=()
    if ! no_custom_shortcuts; then
        squashed="$(squash "$CUSTOM_FILE")"
        if [[ "$squashed" != \{*\} ]]; then
            echo "error: $CUSTOM_FILE does not look like a COSMIC shortcuts" >&2
            echo "file, so it was left alone." >&2
            exit 1
        fi
        # Never replace a key you set yourself.
        for i in "${!KEY_PATTERNS[@]}"; do
            [[ "$squashed" == *"${KEY_PATTERNS[$i]}"* ]] && clash+=("${KEY_NAMES[$i]}")
        done
        if (( ${#clash[@]} )); then
            echo "error: you already use ${clash[*]} for your own shortcut," >&2
            echo "so nothing was changed." >&2
            exit 1
        fi
    fi

    mkdir -p "$STATE_DIR" "$CUSTOM_DIR"
    rm -f "$BEFORE_FILE" "$NONE_MARK"
    if [[ -f "$CUSTOM_FILE" ]]; then
        cp "$CUSTOM_FILE" "$BEFORE_FILE"
    else
        touch "$NONE_MARK"
    fi

    if no_custom_shortcuts; then
        cp "$KEYS_FILE" "$CUSTOM_FILE"
    else
        # Keep your shortcuts and add ours before the closing brace.
        # COSMIC reads a trailing comma fine, so every entry gets one.
        local body new
        body="$(sed '1d;$d' "$KEYS_FILE")"
        new="$(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/}[[:space:]]*$//' "$CUSTOM_FILE")"
        new="$(printf '%s' "$new" | sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[[:space:]]*$//')"
        [[ "$new" == *, || "$new" == *\{ ]] || new="$new,"
        printf '%s\n%s\n}\n' "$new" "$body" > "$CUSTOM_FILE.tmp"
        mv "$CUSTOM_FILE.tmp" "$CUSTOM_FILE"
    fi
    cp "$CUSTOM_FILE" "$AFTER_FILE"

    echo "Added: Super+Return (terminal), Super+Shift+Return and"
    echo "Super+Shift+B (browser), Super+Shift+F (file manager)."
    echo "Your own shortcuts are kept. If a key does nothing yet, log out"
    echo "and back in."
}

remove() {
    if [[ ! -f "$AFTER_FILE" ]]; then
        echo "The Omarchy-style shortcuts were not added by this script."
        echo "Nothing to do."
        return
    fi
    # Only undo if the file still holds exactly what --apply wrote. If
    # you changed shortcuts in Settings since, COSMIC rewrote it.
    if ! cmp -s "$AFTER_FILE" "$CUSTOM_FILE"; then
        echo "error: your shortcuts have changed since these were added" >&2
        echo "(perhaps in Settings), so they were left alone. Remove the" >&2
        echo "four keys by hand in COSMIC's Settings, under the keyboard" >&2
        echo "shortcuts' custom section." >&2
        exit 1
    fi
    if [[ -f "$NONE_MARK" ]]; then
        rm -f "$CUSTOM_FILE"
    else
        cp "$BEFORE_FILE" "$CUSTOM_FILE"
    fi
    rm -rf "$STATE_DIR"
    echo "Removed the Omarchy-style shortcuts. Your own shortcuts and"
    echo "COSMIC's keys are as they were. If a key still works, log out"
    echo "and back in."
}

case "${1:-}" in
    --apply) apply ;;
    --remove) remove ;;
    *) usage; exit 1 ;;
esac
