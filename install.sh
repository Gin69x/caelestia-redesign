#!/usr/bin/env bash
# =============================================================================
# caelestia-redesign — Install Script
# =============================================================================
# Run as your normal user (NOT root). Tested on Arch Linux.
# =============================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[ OK ]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $*"; }
die()     { echo -e "${RED}${BOLD}[ERR ]${RESET} $*"; exit 1; }

[[ $EUID -eq 0 ]] && die "Do not run as root."
command -v pacman &>/dev/null || die "Arch Linux required."

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Repo: $REPO"

# ── AUR helper ────────────────────────────────────────────────────────────────
if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    info "Installing paru..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru-install
    (cd /tmp/paru-install && makepkg -si --noconfirm)
fi
AUR=$(command -v paru || command -v yay)
success "AUR helper: $AUR"

# ── Packages ──────────────────────────────────────────────────────────────────
PACMAN_PKGS=(
    hyprland hypridle hyprlock hyprpicker hyprsunset
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs
    pipewire pipewire-pulse wireplumber pavucontrol
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-fira-sans
    noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
    foot thunar mpv btop fish jq swww
    wl-clipboard cliphist slurp grim
    trash-cli networkmanager blueman
    gnome-keyring polkit-gnome
    vesktop python-materialyoucolor
    caelestia-cli caelestia-meta caelestia-shell
)

AUR_PKGS=(
    quickshell-git
    ttf-rubik-vf
    ttf-material-symbols-variable-git
    zen-browser-bin
    swappy wl-gammarelay-rs
    qt6ct-kde matugen-bin libcava
    libastal-hyprland-git libastal-wireplumber-git
    libastal-mpris-git libastal-network-git
    libastal-notifd-git libastal-battery-git
    libastal-io-git libastal-tray-git
    app2unit
)

info "Installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || warn "Some pacman packages failed — continuing."

info "Installing AUR packages..."
$AUR -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages failed — continuing."

success "Packages installed."

# ── Directories ───────────────────────────────────────────────────────────────
info "Creating directories..."
mkdir -p \
    "$HOME/.config/hypr/scheme" \
    "$HOME/.config/hypr/hyprland" \
    "$HOME/.config/hypr/scripts" \
    "$HOME/.config/caelestia" \
    "$HOME/.config/quickshell" \
    "$HOME/Pictures/Wallpapers/Animated"

# ── Hyprland configs ──────────────────────────────────────────────────────────
info "Copying Hyprland configs..."
cp -r "$REPO/hypr/hyprland/." "$HOME/.config/hypr/hyprland/"
cp    "$REPO/hypr/scheme/default.conf" "$HOME/.config/hypr/scheme/"
cp    "$REPO/hypr/hyprland.conf"       "$HOME/.config/hypr/"
cp    "$REPO/hypr/variables.conf"      "$HOME/.config/hypr/"

info "Copying scripts..."
cp "$REPO/hypr/scripts/"* "$HOME/.config/hypr/scripts/"
chmod +x "$HOME/.config/hypr/scripts/"*

# ── Caelestia config ──────────────────────────────────────────────────────────
info "Copying Caelestia config..."
cp "$REPO/caelestia/shell.json"    "$HOME/.config/caelestia/shell.json"
cp "$REPO/caelestia/hypridle.conf" "$HOME/.config/caelestia/hypridle.conf"

# Only write hypr-user.conf if not already present (preserve user customisations)
if [[ ! -f "$HOME/.config/caelestia/hypr-user.conf" ]]; then
    cp "$REPO/caelestia/hypr-user.conf.example" "$HOME/.config/caelestia/hypr-user.conf"
    warn "Created hypr-user.conf from example — edit it to set your cursor and monitor layout."
fi

[[ ! -f "$HOME/.config/caelestia/hypr-vars.conf" ]] && touch "$HOME/.config/caelestia/hypr-vars.conf"

# ── Quickshell config ─────────────────────────────────────────────────────────
info "Copying Quickshell config..."
cp -r "$REPO/quickshell/caelestia" "$HOME/.config/quickshell/"
chmod +x "$HOME/.config/quickshell/caelestia/utils/scripts/wallpaper-audio" 2>/dev/null || true

# ── Custom colour schemes ─────────────────────────────────────────────────────
if [[ -d "$REPO/schemes" ]]; then
    info "Installing custom colour schemes..."
    SCHEMES_DIR="/usr/lib/python3.13/site-packages/caelestia/data/schemes"
    for scheme_dir in "$REPO/schemes"/*/; do
        name=$(basename "$scheme_dir")
        if [[ ! -d "$SCHEMES_DIR/$name" ]]; then
            sudo mkdir -p "$SCHEMES_DIR/$name"
            sudo cp -r "$scheme_dir/." "$SCHEMES_DIR/$name/"
            success "Scheme installed: $name"
        else
            warn "Scheme '$name' already exists — skipping."
        fi
    done
fi

# ── Fish shell ────────────────────────────────────────────────────────────────
if command -v fish &>/dev/null && [[ "$SHELL" != "$(command -v fish)" ]]; then
    info "Setting fish as default shell..."
    grep -q "$(command -v fish)" /etc/shells || echo "$(command -v fish)" | sudo tee -a /etc/shells
    chsh -s "$(command -v fish)"
    success "Default shell set to fish (takes effect on next login)."
fi

# ── Services ──────────────────────────────────────────────────────────────────
info "Enabling user audio services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

info "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager 2>/dev/null || true

xdg-user-dirs-update 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Done! Log out and select Hyprland.${RESET}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${BOLD}After logging in:${RESET}"
echo -e "  • Drop wallpapers into ${BOLD}~/Pictures/Wallpapers/Animated/${RESET}"
echo -e "  • Pair audio: same filename as GIF (e.g. wall.gif + wall.mp3)"
echo -e "  • Press ${BOLD}Super${RESET} to open launcher"
echo -e "  • Edit ${BOLD}~/.config/caelestia/hypr-user.conf${RESET} for monitor/cursor"
echo ""
