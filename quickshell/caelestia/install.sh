#!/usr/bin/env bash
# =============================================================================
# Gin's Hyprland Environment — Install Script
# =============================================================================
# Installs all dependencies, copies configs, and sets up the environment.
# Run as your normal user (NOT root). sudo will be invoked where needed.
# =============================================================================

set -e

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $*"; }
die()     { echo -e "${RED}${BOLD}[ERR]${RESET}  $*"; exit 1; }

# ── Sanity checks ─────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Do not run this script as root."
command -v pacman &>/dev/null || die "This script requires an Arch-based distro."

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Repo directory: $REPO_DIR"

# ── AUR helper ────────────────────────────────────────────────────────────────
if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    info "Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru-install
    (cd /tmp/paru-install && makepkg -si --noconfirm)
    rm -rf /tmp/paru-install
fi
AUR_HELPER=$(command -v paru || command -v yay)
success "AUR helper: $AUR_HELPER"

# ── Package lists ─────────────────────────────────────────────────────────────
PACMAN_PKGS=(
    # Hyprland & wayland
    hyprland hypridle hyprlock hyprpicker hyprsunset
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs

    # Audio
    pipewire pipewire-pulse wireplumber pavucontrol

    # Fonts
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
    ttf-fira-sans

    # Apps & tools
    foot thunar mpv btop fish jq
    swww wl-clipboard cliphist slurp grim
    trash-cli app2unit networkmanager blueman
    gnome-keyring polkit-gnome
    nwg-look pavucontrol noto-fonts-emoji

    # Caelestia
    caelestia-cli caelestia-meta caelestia-shell

    # Misc
    vesktop python-materialyoucolor
)

AUR_PKGS=(
    quickshell-git
    ttf-rubik-vf
    ttf-material-symbols-variable-git
    zen-browser-bin
    hyprpicker
    swappy
    wl-gammarelay-rs
    qt6ct-kde
    matugen-bin
    libcava
    libastal-hyprland-git
    libastal-wireplumber-git
    libastal-mpris-git
    libastal-network-git
    libastal-notifd-git
    libastal-battery-git
    libastal-io-git
    libastal-tray-git
    app2unit
)

# ── Install packages ──────────────────────────────────────────────────────────
info "Installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || warn "Some pacman packages may have failed — continuing."

info "Installing AUR packages..."
$AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages may have failed — continuing."

success "Packages installed."

# ── Create required directories ───────────────────────────────────────────────
info "Creating directories..."
mkdir -p \
    "$HOME/.config/hypr/scheme" \
    "$HOME/.config/hypr/hyprland" \
    "$HOME/.config/hypr/scripts" \
    "$HOME/.config/caelestia" \
    "$HOME/.config/quickshell" \
    "$HOME/Pictures/Wallpapers/Animated"

# ── Copy configs ──────────────────────────────────────────────────────────────
info "Copying Hyprland configs..."
cp -r "$REPO_DIR/hypr/hyprland/"*  "$HOME/.config/hypr/hyprland/"
cp -r "$REPO_DIR/hypr/scheme/"*    "$HOME/.config/hypr/scheme/"
cp    "$REPO_DIR/hypr/hyprland.conf"  "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || true
cp    "$REPO_DIR/hypr/variables.conf" "$HOME/.config/hypr/variables.conf" 2>/dev/null || true

info "Copying scripts..."
cp "$REPO_DIR/hypr/scripts/"* "$HOME/.config/hypr/scripts/"
chmod +x "$HOME/.config/hypr/scripts/"*

info "Copying Caelestia config..."
cp "$REPO_DIR/caelestia/shell.json"     "$HOME/.config/caelestia/shell.json"
cp "$REPO_DIR/caelestia/hypridle.conf"  "$HOME/.config/caelestia/hypridle.conf"
# hypr-user.conf and hypr-vars.conf are user-specific — only copy if not present
[[ ! -f "$HOME/.config/caelestia/hypr-user.conf" ]] && \
    cp "$REPO_DIR/caelestia/hypr-user.conf.example" "$HOME/.config/caelestia/hypr-user.conf" 2>/dev/null || true
[[ ! -f "$HOME/.config/caelestia/hypr-vars.conf" ]] && \
    touch "$HOME/.config/caelestia/hypr-vars.conf"

info "Copying Quickshell config..."
cp -r "$REPO_DIR/quickshell/caelestia" "$HOME/.config/quickshell/caelestia"

# ── Symlink ~/.config/hypr ────────────────────────────────────────────────────
# Caelestia expects hyprland configs under ~/.config/hypr/hyprland/
# The main hyprland.conf sources from ~/caelestia/hypr — we replicate that here
info "Setting up hypr config symlinks..."
if [[ ! -L "$HOME/.config/hypr" ]] && [[ -d "$HOME/.config/hypr" ]]; then
    success "~/.config/hypr already exists as a real directory — configs copied directly."
fi

# ── Install custom themes ─────────────────────────────────────────────────────
if [[ -d "$REPO_DIR/schemes" ]]; then
    info "Installing custom colour schemes..."
    for scheme_dir in "$REPO_DIR/schemes"/*/; do
        scheme_name=$(basename "$scheme_dir")
        target="/usr/lib/python3.13/site-packages/caelestia/data/schemes/$scheme_name"
        if [[ ! -d "$target" ]]; then
            sudo mkdir -p "$target"
            sudo cp -r "$scheme_dir"* "$target/"
            success "Installed scheme: $scheme_name"
        else
            warn "Scheme '$scheme_name' already exists — skipping."
        fi
    done
fi

# ── wallpaper-audio script ────────────────────────────────────────────────────
info "Installing wallpaper-audio script..."
AUDIO_SCRIPT="$HOME/.config/quickshell/caelestia/utils/scripts/wallpaper-audio"
if [[ -f "$AUDIO_SCRIPT" ]]; then
    chmod +x "$AUDIO_SCRIPT"
    success "wallpaper-audio script is executable."
fi

# ── Fish shell ────────────────────────────────────────────────────────────────
if command -v fish &>/dev/null; then
    info "Setting fish as default shell..."
    if ! grep -q "$(command -v fish)" /etc/shells; then
        echo "$(command -v fish)" | sudo tee -a /etc/shells
    fi
    # Only change if user hasn't already set it
    if [[ "$SHELL" != "$(command -v fish)" ]]; then
        chsh -s "$(command -v fish)"
        success "Default shell changed to fish. Takes effect on next login."
    fi
fi

# ── Enable services ───────────────────────────────────────────────────────────
info "Enabling user services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

info "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager 2>/dev/null || true

# ── swww daemon autostart ─────────────────────────────────────────────────────
# Already handled by exec-once = swww-daemon in hypr-user.conf

# ── XDG user dirs ─────────────────────────────────────────────────────────────
xdg-user-dirs-update 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Installation complete!${RESET}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. Log out and select ${BOLD}Hyprland${RESET} from your display manager"
echo -e "  2. Drop your wallpapers into ${BOLD}~/Pictures/Wallpapers/Animated/${RESET}"
echo -e "  3. Press ${BOLD}Super${RESET} to open the launcher"
echo -e "  4. Edit ${BOLD}~/.config/caelestia/hypr-vars.conf${RESET} for personal overrides"
echo ""
warn "If you use a custom cursor theme, set HYPRCURSOR_THEME in hypr-user.conf"
warn "Reboot recommended after first install for all services to initialise cleanly."
echo ""
