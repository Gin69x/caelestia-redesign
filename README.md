# caelestia-redesign

A heavily modified fork of [Caelestia](https://github.com/caelestia-dots) built on [Quickshell](https://quickshell.outfoxxed.me/) and [Hyprland](https://hyprland.org/), featuring a completely redesigned shell layout, animated GIF wallpapers with synced audio, a dynamic lock screen, task manager, extended utilities panel, and a custom red/black `montagem` colour scheme. All components continue to follow Caelestia's theming system.

---

## Screenshots

| Dashboard + Sidebar | Top Bar |
|---|---|
| ![dashboard](https://i.imgur.com/placeholder1.png) | ![bar](https://i.imgur.com/placeholder2.png) |

| Lock Screen | Task Manager |
|---|---|
| ![lock](https://i.imgur.com/placeholder3.png) | ![taskmanager](https://i.imgur.com/placeholder4.png) |

---

## What's Changed From Caelestia

### Layout

| Component | Original Caelestia | This Fork |
|---|---|---|
| Top bar | Full horizontal bar with all widgets | Minimal top bar — workspaces, active window, clock, tray |
| Left panel | None | New vertical **DashSidebar** with dashboard + notifications |
| Utilities drawer | Basic toggles + recording | Expanded: media card, network panel, bluetooth panel, power card, toggles |
| Dock | None | New app dock (`modules/dock/`) |

### New Modules (not in original Caelestia)

- **`modules/dashsidebar/`** — Vertical sidebar replacing the original bar's dashboard role. Contains `DashSidebar.qml`, `DashSidebarWindow.qml`, `DashSidebarPreview.qml`, `BorderWindow.qml`
- **`modules/dock/`** — App dock. `DockBar.qml`, `DockWindow.qml`
- **`modules/taskmanager/`** — Full task manager (open with `Super + Esc`). Shows running apps and system processes with CPU/memory usage. `TaskManager.qml`, `TaskManagerFactory.qml`, `ProcessesTab.qml`, `ServicesTab.qml`
- **`modules/lock/AlbumAccentColor.qml`** — Extracts dominant colour from the currently playing song's album art thumbnail
- **`modules/lock/MediaLockContent.qml`** — Dynamic lock screen layout used when media is playing
- **`modules/utilities/cards/BluetoothPanel.qml`** — Bluetooth device management in utilities drawer
- **`modules/utilities/cards/MediaCard.qml`** — Now-playing card in utilities drawer
- **`modules/utilities/cards/NetworkPanel.qml`** — Wi-Fi network list + speed monitor in utilities drawer
- **`modules/utilities/cards/PowerCard.qml`** — Power profile switcher in utilities drawer
- **`modules/controlcenter/wifi/`** — Full Wi-Fi settings pane (`WifiPane.qml`, `NetworkList.qml`, `NetworkDetails.qml`, `NetworkSettings.qml`)
- **`modules/controlcenter/bluetooth/`** — Full Bluetooth settings pane (kept from upstream Caelestia but wired into the redesigned control center)

### Modified Files (changed from original Caelestia)

| File | What Changed |
|---|---|
| `shell.qml` | Wires in dashsidebar, dock, taskmanager; removes original bar role |
| `modules/bar/BarWrapper.qml` | Redesigned as slim top bar only |
| `modules/bar/DashSidebarWrapper.qml` | **New** — wrapper that positions the sidebar |
| `modules/bar/components/workspaces/` | Restyled workspace indicators (ActiveIndicator, OccupiedBg, SpecialWorkspaces, Workspace, Workspaces) |
| `modules/drawers/Drawers.qml` | Updated to account for new sidebar + dock geometry |
| `modules/drawers/Backgrounds.qml` | Blur/background adjustments for new layout |
| `modules/drawers/Interactions.qml` | Interaction zones updated for sidebar |
| `modules/drawers/Panels.qml` | Panel sizing updated for new layout |
| `modules/controlcenter/Panes.qml` | Added Network and Bluetooth panes |
| `modules/controlcenter/Session.qml` | Minor layout adjustments |
| `modules/dashboard/Content.qml` | Adapted for sidebar context |
| `modules/lock/Content.qml` | Dynamic lock — uses album art colour when media plays, standard lock when not |
| `modules/lock/LockSurface.qml` | Passes album accent colour through to background |
| `modules/lock/NotifGroup.qml` | Notification styling on lock screen |
| `modules/utilities/Content.qml` | Adds media card, network panel, bluetooth panel, power card |
| `modules/utilities/Wrapper.qml` | Layout updated for expanded utilities |
| `modules/utilities/cards/Toggles.qml` | Additional quick toggles added |
| `modules/Shortcuts.qml` | Added `Super + Esc` → task manager |
| `services/Wallpapers.qml` | swww instead of caelestia wallpaper; GIF + per-wallpaper audio sync |
| `services/Brightness.qml` | Minor adjustments |
| `services/IdleInhibitor.qml` | Minor adjustments |
| `services/Network.qml` | Wired into new network panel |
| `config/UserPaths.qml` | Wallpaper dir set to `~/Pictures/Wallpapers/Animated` |
| `config/UtilitiesConfig.qml` | Toast config adjustments |
| `utils/Images.qml` | Added GIF to valid image extensions |

---

## Animated Wallpaper + Audio

Drop files into `~/Pictures/Wallpapers/Animated/`. To pair audio with a GIF, use the same basename:

```
~/Pictures/Wallpapers/Animated/
├── mywall.gif
└── mywall.mp3   ← loops automatically when mywall.gif is selected
```

Supported audio formats: `mp3 ogg flac wav opus m4a`

Audio starts after swww's transition (~4.3s) and loops until you switch wallpaper. On login, the last wallpaper and its audio are automatically restored.

---

## Dynamic Lock Screen

- **Media playing** → lock screen background takes the dominant colour from the current song's album art (`AlbumAccentColor.qml` + `MediaLockContent.qml`)
- **No media** → standard Caelestia lock screen with slight layout modifications
- All colours still follow Caelestia's active colour scheme

---

## Install

```bash
git clone https://github.com/Gin69x/caelestia-redesign.git
cd caelestia-redesign
bash install.sh
```

Log out → select **Hyprland** → log back in.

---

## Key Bindings

| Binding | Action |
|---|---|
| `Super` | Launcher |
| `Super + Esc` | Task manager |
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
| `Ctrl+Shift+Esc` | System monitor (btop) |
| `Ctrl+Super+Shift+R` | Restart shell |

---

## Customisation

- Personal overrides: `~/.config/caelestia/hypr-user.conf` (not tracked)
- Variable overrides: `~/.config/caelestia/hypr-vars.conf` (not tracked)
- Edit `~/.config/caelestia/shell.json` for launcher actions, default apps, weather location

---

## Custom Colour Schemes

This repo includes the `montagem` scheme — deep black base with `#E90023` red as primary. Switch via `>scheme` in the launcher.

---

## Credits

- [Caelestia](https://github.com/caelestia-dots) — original shell, CLI framework, and theming system
- [Quickshell](https://quickshell.outfoxxed.me/) — QML shell compositor
- [swww](https://github.com/LGFae/swww) — animated wallpaper daemon
