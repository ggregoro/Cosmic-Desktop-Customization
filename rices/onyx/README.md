# Onyx rice

One of several rices in this repo — see the [top-level README](../../README.md) for
the full list.

> **⚠️ Unverified / hand-authored, unlike the other two rices.** [Onyx](
> https://github.com/ggregoro/onyx) is an [Omarchy](https://omarchy.org/) theme —
> a `colors.toml` palette that Omarchy's own tooling expands into Hyprland,
> Waybar, btop, etc. None of that exists for COSMIC. The `cosmic/` config here was
> **hand-derived** from Onyx's palette rather than captured live through COSMIC
> Settings (unlike [`milky-way`](../milky-way/README.md) and
> [`osaka-jade`](../osaka-jade/README.md), both real snapshots). COSMIC's theme
> engine expands one seed accent color into ~15 interdependent derived shades per
> role via its own algorithm — these values are a manual best-effort approximation
> of that, not COSMIC's actual output, and may render slightly differently than
> intended. **Apply it, then use COSMIC Settings → Appearance to fine-tune the
> accent to taste** — at that point it'll self-correct into a real, valid COSMIC
> theme and can be re-snapshotted like the other two rices.

## Source palette (Onyx, for Omarchy/Hyprland)

`background = #000000`, `foreground = #ffffff`, `accent = #8d8d8d` (grey — a
"stark pure-black background, white foreground, greyscale UI accents" theme,
per Onyx's own README), plus 8 real ANSI terminal colors so text stays readable
despite the near-monochrome desktop.

## What was ported vs. what wasn't

| Onyx element | Status here |
|---|---|
| Wallpaper | Ported directly — `Dark Street Light.jpeg`, one of Onyx's 5 bundled backgrounds |
| `background`/`foreground` (`#000000`/`#ffffff`) | Ported — mapped onto COSMIC's background/primary/secondary elevation tiers |
| `accent` (`#8d8d8d` grey) | Ported — hand-derived hover/pressed/disabled shades (see caveat above) |
| `Yaru-blue` icon theme | **Not applied** — not in Fedora's default repos (would need a COPR); optional, see below |
| 8-color ANSI terminal palette | **Not applied** — COSMIC's tracked config has no ANSI-palette field; that lives in whichever terminal app you use (Ghostty on this box), not in `~/.config/cosmic`. Porting it means hand-writing a Ghostty theme from [Onyx's `colors.toml`](https://github.com/ggregoro/onyx/blob/master/colors.toml) separately — not done here |

## Trying this on your own machine

1. **Back up your own config first**:
   ```bash
   cp -r ~/.config/cosmic ~/.config/cosmic.bak
   ```
2. **Clone this repo and copy its config in:**
   ```bash
   git clone https://github.com/ggregoro/Cosmic-Desktop-Customization.git /tmp/cosmic-setup
   cp -r /tmp/cosmic-setup/rices/onyx/cosmic/. ~/.config/cosmic/
   ```
3. **Set the wallpaper path.** The tracked config points at
   `/home/grego/Pictures/Dark Street Light.jpeg`. Grab the same image from
   [Onyx's `backgrounds/`](https://github.com/ggregoro/onyx/tree/master/backgrounds)
   (or use another of its 5), save it under your own `$HOME`, and edit the
   `source:` path in `~/.config/cosmic/com.system76.CosmicBackground/v1/all` to
   match.
4. **Force dark mode** (not file-based, so not tracked here):
   ```bash
   gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
   ```
5. **(Optional) Yaru-blue icons** — install via whatever your distro offers (a
   COPR on Fedora, official repos on Pop!_OS/Ubuntu, AUR on Arch — not verified
   here), then:
   ```bash
   gsettings set org.gnome.desktop.interface icon-theme 'Yaru-blue'
   ```
6. **Open COSMIC Settings → Desktop → Appearance** and nudge the accent color
   to taste — this both fixes any rough edges in the hand-derived shades above
   and lets COSMIC regenerate a fully-correct theme from your final choice.

COSMIC's settings daemon watches these config files live — most changes apply
within a second or two of a file being written, no reload or logout needed.

## Restoring / reverting

- Switch to [`milky-way`](../milky-way/README.md) or
  [`osaka-jade`](../osaka-jade/README.md)'s config instead, or restore your own
  `~/.config/cosmic.bak` from step 1 above.
