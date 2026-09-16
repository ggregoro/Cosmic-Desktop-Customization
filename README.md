# Cosmic Desktop Customization

Tracked configuration for a redesigned [COSMIC](https://system76.com/cosmic)
desktop, on Greg's Dell E7450 laptop. Each subdirectory under `rices/` is a
self-contained rice — its own `cosmic/` config, its own README, and (where
the rice was captured live rather than hand-built) its own screenshots. Only
`rices/` and this file are tracked (see `.gitignore`); everything else under
`~/.config` (browser profiles, app caches, unrelated app settings) is
deliberately left out.

## Rices

| Rice | Look | Base system | Source |
|---|---|---|---|
| [`milky-way`](rices/milky-way/README.md) | Milky Way core wallpaper, squared-off corners, persistent full-width dock, Yaru theme | Pop!_OS 24.04 / Arch Linux | Live snapshot |
| [`osaka-jade`](rices/osaka-jade/README.md) | Green/jade neon cityscape wallpaper, jade accent color, floating auto-hide dock, stock COSMIC theme | Fedora Linux 44 (COSMIC Spin) | Live snapshot |
| [`onyx`](rices/onyx/README.md) | Pure-black/grey [Onyx](https://github.com/ggregoro/onyx) palette ported from Omarchy, `Dark Street Light` wallpaper | Any COSMIC distro (untested live) | ⚠️ Hand-derived, not yet verified live — see its README |

![Osaka Jade desktop](rices/osaka-jade/screenshots/desktop.png)

## Trying one on your own machine

Each rice's own README has the full walkthrough (packages required, exact
`cp`/`git checkout` commands, wallpaper caveats). In short, for any rice:

1. Back up your own `~/.config/cosmic` first.
2. Clone this repo.
3. Copy `rices/<name>/cosmic/` into `~/.config/cosmic/`.
4. Point the wallpaper config at your own copy of the image (the tracked path is
   absolute and won't exist on your machine).

## Restoring / reverting

- `git log` shows the full history from `pre-claude-baseline` (the state of
  `~/.config/cosmic` before this project started, back when the repo tracked
  only the `milky-way` rice at its root) through every change since, including
  the move to the current `rices/<name>/` layout.
- Each rice's own README has a rice-specific revert command.
