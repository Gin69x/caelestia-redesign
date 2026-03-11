# Gin's Hyprland Environment

A customised Hyprland desktop built on top of [Caelestia CLI](https://github.com/caelestia-dots/cli) and [Quickshell](https://quickshell.outfoxxed.me/), featuring animated GIF wallpapers with synced audio, a fully themed shell, and a clean install script for Arch Linux.

---

## Preview

> Wallpaper picker supports animated GIFs. Special wallpapers can have a paired audio file (same filename, e.g. `montagem.gif` + `montagem.mp3`) that loops automatically when selected.

---

## Features

- **Hyprland** — tiling Wayland compositor with polished animations, gestures, and workspace groups
- **Caelestia shell** (Quickshell) — bar, launcher, notifications, dashboard, control center, OSD
- **Animated wallpapers** — GIF support via `swww` with per-wallpaper looping audio via `mpv`
- **Dynamic colour schemes** — `caelestia scheme` + custom `montagem` theme included
- **Custom launcher actions** — colour picker, task manager, wallpaper gallery, scheme switcher
- **Fish shell** default with clean keybinds
- **Auto-restore** — wallpaper and its audio resume on login

---

## Requirements

- Arch Linux (or Arch-based distro)
- `paru` or `yay` (AUR helper — will be installed automatically if missing)
- A working GPU driver and Wayland support

---

## Installation

```bash
git clone https://github.com/yourusername/your-repo.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

Log out, select **Hyprland** from your display manager, and log back in.

---

## Directory Structure

```
.
├── install.sh                  # One-shot install script
├── README.md
│
├── hypr/                       # Hyprland config
│   ├── hyprland.conf           # Main entry point
│   ├── variables.conf          # Keybinds, gaps, fonts, etc.
│   ├── hyprland/               # Modular sub-configs
│   │   ├── animations.conf
│   │   ├── decoration.conf
│   │   ├── env.conf
│   │   ├── execs.conf
│   │   ├── general.conf
│   │   ├── gestures.conf
│   │   ├── group.conf
│   │   ├── input.conf
│   │   ├── keybinds.conf
│   │   ├── misc.conf
│   │   └── rules.conf
│   ├── scheme/
│   │   └── default.conf        # Default colour scheme (sourced by hyprland)
│   └── scripts/
│       ├── startup-lock.sh
│       ├── wsaction.fish
│       └── kill-caelestia-wallpaper.sh
│
├── caelestia/                  # Caelestia CLI config
│   ├── shell.json              # Main shell config (apps, launcher actions, etc.)
│   ├── hypridle.conf
│   └── hypr-user.conf.example  # Template — copied to ~/.config/caelestia/hypr-user.conf
│
├── quickshell/
│   └── caelestia/              # Your modified Quickshell shell
│       ├── shell.qml
│       ├── services/
│       │   └── Wallpapers.qml  # swww + GIF audio sync
│       ├── utils/
│       │   ├── Images.qml      # GIF support added
│       │   └── scripts/
│       │       └── wallpaper-audio  # Companion audio launcher
│       └── ...
│
└── schemes/                    # Custom caelestia colour schemes
    └── montagem/
        └── default/
            └── dark.txt
```

---

## Animated Wallpaper + Audio

Place your wallpapers in `~/Pictures/Wallpapers/Animated/`. To pair audio with a GIF, place an audio file with the same basename next to it:

```
~/Pictures/Wallpapers/Animated/
├── montagem.gif
└── montagem.mp3   ← plays automatically when montagem.gif is selected
```

Supported audio formats: `mp3`, `ogg`, `flac`, `wav`, `opus`, `m4a`

The audio starts after swww's transition finishes (~4.3s) and loops indefinitely. Switching to a non-GIF wallpaper stops the audio immediately.

---

## Key Bindings

| Binding | Action |
|---|---|
| `Super` | Open launcher |
| `Super + T` | Terminal (foot) |
| `Super + W` | Browser (Zen) |
| `Super + E` | File manager (Thunar) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + L` | Lock screen |
| `Super + M` | Music workspace |
| `Super + D` | Communication workspace |
| `Ctrl+Shift+Esc` | System monitor |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + Shift + S` | Screenshot region |
| `Ctrl+Super+Shift+R` | Restart shell |

---

## Customisation

- **Personal overrides**: `~/.config/caelestia/hypr-vars.conf` (not tracked by git)
- **Window rules / execs**: `~/.config/caelestia/hypr-user.conf` (not tracked by git)
- **Scheme**: run `>scheme` in the launcher to switch colour scheme
- **Wallpaper**: run `>wallpaper` in the launcher

---

## Credits

- [Caelestia](https://github.com/caelestia-dots) — CLI framework and shell base
- [Quickshell](https://quickshell.outfoxxed.me/) — QML shell compositor
- [swww](https://github.com/LGFae/swww) — animated wallpaper daemon
