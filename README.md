# caelestia-redesign

A customised Hyprland desktop built on [Caelestia](https://github.com/caelestia-dots) and [Quickshell](https://quickshell.outfoxxed.me/), featuring animated GIF wallpapers with synced audio, a red/black `montagem` colour scheme, and a one-shot install script for Arch Linux.

---

## Preview

> `Super` opens the launcher. `>wallpaper` to browse GIFs. `>scheme` to switch colour scheme.

---

## Features

- **Hyprland** — tiling Wayland compositor, workspace groups, gestures, polished animations
- **Caelestia shell** (Quickshell) — bar, launcher, notifications, dashboard, control center, OSD
- **Animated GIF wallpapers** via `swww` — audio synced per-wallpaper (place a `.mp3` next to your `.gif`)
- **montagem** colour scheme — deep black with `#E90023` red as primary
- **Custom launcher actions** — colour picker, task killer, wallpaper gallery, scheme/variant switcher
- **Fish** default shell
- Wallpaper + audio auto-restore on login

---

## Install

```bash
git clone https://github.com/yourusername/caelestia-redesign.git
cd caelestia-redesign
bash install.sh
```

Log out → select **Hyprland** → log back in.

---

## Wallpapers & Audio

Drop files into `~/Pictures/Wallpapers/Animated/`. To pair audio with a GIF, name them identically:

```
~/Pictures/Wallpapers/Animated/
├── mywall.gif
└── mywall.mp3   ← loops automatically when mywall.gif is selected
```

Supported audio formats: `mp3 ogg flac wav opus m4a`

The audio starts after swww's transition finishes (~4.3s) and loops until you switch wallpaper.

---

## Cursor

The cursor is not included. Install any Xcursor-compatible theme and set it in `~/.config/caelestia/hypr-user.conf`:

```ini
env = HYPRCURSOR_THEME, YourThemeName
env = XCURSOR_THEME, YourThemeName
env = HYPRCURSOR_SIZE, 32
env = XCURSOR_SIZE, 32
```

---

## Structure

```
.
├── install.sh
├── hypr/
│   ├── hyprland.conf          # Main entry point
│   ├── variables.conf         # Keybinds, gaps, apps, etc.
│   ├── hyprland/              # Modular sub-configs
│   ├── scheme/default.conf    # Default colour scheme
│   └── scripts/               # startup-lock, wsaction, etc.
├── caelestia/
│   ├── shell.json             # Launcher actions, apps, services
│   ├── hypridle.conf
│   └── hypr-user.conf.example # Copy → ~/.config/caelestia/hypr-user.conf
├── quickshell/caelestia/      # Modified Quickshell shell
│   ├── services/Wallpapers.qml   # swww + GIF audio sync
│   └── utils/scripts/wallpaper-audio
└── schemes/montagem/          # Custom red/black colour scheme
```

---

## Key Bindings

| Binding | Action |
|---|---|
| `Super` | Launcher |
| `Super + T` | Terminal (foot) |
| `Super + W` | Browser (Zen) |
| `Super + E` | File manager (Thunar) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + L` | Lock |
| `Super + M` | Music workspace |
| `Super + D` | Communications |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + Shift + S` | Screenshot region |
| `Ctrl+Shift+Esc` | System monitor |
| `Ctrl+Super+Shift+R` | Restart shell |

---

## Customisation

- Personal overrides: `~/.config/caelestia/hypr-user.conf` (not tracked)
- Variable overrides: `~/.config/caelestia/hypr-vars.conf` (not tracked)

---

## Credits

- [Caelestia](https://github.com/caelestia-dots) — CLI + shell framework
- [Quickshell](https://quickshell.outfoxxed.me/) — QML shell
- [swww](https://github.com/LGFae/swww) — animated wallpaper daemon
