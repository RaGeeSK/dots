#!/usr/bin/env bash
set -euo pipefail

# ======================================================
# Скрипт полного переноса системы
# - устанавливает все пакеты
# - копирует все конфиги из папок рядом со скриптом
#
# Использование:
#   ./install-configs.sh [--no-pkgs]
# ======================================================

SELF="$(cd "$(dirname "$0")" && pwd)"
DST="${HOME}"
INSTALL_PKGS=true

for arg in "$@"; do
  [ "$arg" = "--no-pkgs" ] && INSTALL_PKGS=false
done

# ======================================================
# 1. ПАКЕТЫ
# ======================================================
OFFICIAL_PKGS=(
  7zip adw-gtk-theme awww base base-devel bash-completion
  btop cava celluloid clang cmatrix cool-retro-term cowsay
  discord dunst efibootmgr fastfetch flameshot git
  gnome-calculator gnome-tweaks goverlay grub gtklock
  hyprland hyprlock hyprshot kitty kvantum lact
  lib32-mesa lib32-vulkan-radeon libnetfilter_queue
  libreoffice-fresh linux linux-firmware linux-headers
  lxappearance ly mangohud nano nautilus neovim
  network-manager-applet networkmanager nwg-look obs-studio
  obsidian opencode os-prober otf-font-awesome
  pipewire pipewire-pulse polkit-gnome prismlauncher
  qt5ct qt6ct rustup sddm steam telegram-desktop toilet
  ttf-cascadia-code ttf-hack ttf-jetbrains-mono-nerd
  ttf-opensans waybar wireplumber wl-clipboard woff2-font-awesome
  wofi xdg-desktop-portal-gtk xdg-desktop-portal-hyprland
  xf86-video-vesa xorg-bdftopcf xorg-docs xorg-fonts-100dpi
  xorg-fonts-75dpi xorg-fonts-encodings xorg-font-util
  xorg-iceauth xorg-mkfontscale xorg-server xorg-server-common
  xorg-server-devel xorg-server-src xorg-server-xephyr
  xorg-server-xnest xorg-server-xvfb xorg-sessreg
  xorg-setxkbmap xorg-smproxy xorg-x11perf xorg-xauth
  xorg-xbacklight xorg-xcmsdb xorg-xcursorgen xorg-xdpyinfo
  xorg-xdriinfo xorg-xev xorg-xgamma xorg-xhost xorg-xinput
  xorg-xkbcomp xorg-xkbevd xorg-xkbutils xorg-xkill
  xorg-xlsatoms xorg-xlsclients xorg-xmodmap xorg-xpr
  xorg-xprop xorg-xrandr xorg-xrdb xorg-xrefresh xorg-xset
  xorg-xsetroot xorg-xvinfo xorg-xwayland xorg-xwd
  xorg-xwininfo xorg-xwud yazi zed zsh
)

AUR_PKGS=(
  bubblefetch-git byedpi-bin catppuccin-cursors-mocha
  catppuccin-gtk-theme-mocha cursor-bin happ-desktop-bin
  heroic-games-launcher-bin kvantum-theme-catppuccin-git
  phoronix-test-suite-git portproton spotify swaylock-effects
  yay yay-debug zen-browser-bin zsh-theme-powerlevel10k-git
)

install_packages() {
  echo "=============================================="
  echo " УСТАНОВКА ПАКЕТОВ"
  echo "=============================================="

  if ! command -v pacman &>/dev/null; then
    echo "⚠️  pacman не найден — пропускаю"
    return
  fi

  echo ">>> Установка официальных пакетов..."
  sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}" || true

  AUR_HELPER=""
  for helper in yay paru; do
    if command -v "$helper" &>/dev/null; then
      AUR_HELPER="$helper"
      break
    fi
  done

  if [ -z "$AUR_HELPER" ]; then
    echo ">>> AUR helper не найден. Устанавливаю yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    AUR_HELPER="yay"
    rm -rf /tmp/yay-bin
  fi

  if [ -n "$AUR_HELPER" ]; then
    echo ">>> Установка AUR пакетов через $AUR_HELPER..."
    $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" || true
  fi

  echo "✅ Пакеты установлены"
}

if [ "$INSTALL_PKGS" = true ]; then
  install_packages
fi

# ======================================================
# 2. КОНФИГИ (из локальных папок ~/builder/*)
# ======================================================
echo ""
echo "=============================================="
echo " КОПИРОВАНИЕ КОНФИГОВ"
echo "  Из: $SELF"
echo "  В:  $DST"
echo "=============================================="

cp_file() { local s="$1" d="$2"; mkdir -p "$(dirname "$d")"; cp "$s" "$d" 2>/dev/null && echo "  OK $3" || echo "  — $3"; }
cp_dir()  { local s="$1" d="$2"; mkdir -p "$d"; cp -r "$s/"* "$d/" 2>/dev/null && echo "  OK $3" || echo "  — $3"; }

# --- dotfiles ---
cp_file "$SELF/dotfiles/.bashrc"       "$DST/.bashrc"       ".bashrc"
cp_file "$SELF/dotfiles/.zshrc"       "$DST/.zshrc"       ".zshrc"
cp_file "$SELF/dotfiles/.gtkrc-2.0"   "$DST/.gtkrc-2.0"   ".gtkrc-2.0"
cp_file "$SELF/dotfiles/.p10k.zsh"    "$DST/.p10k.zsh"    ".p10k.zsh"

# --- WM ---
cp_dir "$SELF/wm/hypr"     "$DST/.config/hypr"     "hypr/"
cp_dir "$SELF/wm/waybar"   "$DST/.config/waybar"   "waybar/"
cp_dir "$SELF/wm/wofi"     "$DST/.config/wofi"     "wofi/"
cp_dir "$SELF/wm/dunst"    "$DST/.config/dunst"    "dunst/"
cp_dir "$SELF/wm/swaylock" "$DST/.config/swaylock" "swaylock/"
cp_dir "$SELF/wm/gtklock"  "$DST/.config/gtklock"  "gtklock/"

# --- GTK + Qt ---
cp_file "$SELF/gtk-qt/gtk-3.0/settings.ini" "$DST/.config/gtk-3.0/settings.ini" "gtk-3.0/settings.ini"
cp_file "$SELF/gtk-qt/gtk-3.0/bookmarks"    "$DST/.config/gtk-3.0/bookmarks"    "gtk-3.0/bookmarks"
cp -a "$SELF/gtk-qt/gtk-4.0/"* "$DST/.config/gtk-4.0/" 2>/dev/null && echo "  OK gtk-4.0/" || echo "  — gtk-4.0/"
cp_file "$SELF/gtk-qt/nwg-look/config"       "$DST/.config/nwg-look/config"              "nwg-look/config"
cp_file "$SELF/gtk-qt/xsettingsd/xsettingsd.conf" "$DST/.config/xsettingsd/xsettingsd.conf" "xsettingsd.conf"
cp_dir "$SELF/gtk-qt/qt5ct"  "$DST/.config/qt5ct"    "qt5ct/"
cp_dir "$SELF/gtk-qt/qt6ct"  "$DST/.config/qt6ct"    "qt6ct/"
cp_dir "$SELF/gtk-qt/Kvantum" "$DST/.config/Kvantum" "Kvantum/"

# --- KDE ---
cp_file "$SELF/kde/dolphinrc"    "$DST/.config/dolphinrc"    "dolphinrc"
cp_file "$SELF/kde/kdeglobals"   "$DST/.config/kdeglobals"   "kdeglobals"
cp_file "$SELF/kde/QtProject.conf" "$DST/.config/QtProject.conf" "QtProject.conf"
cp_dir "$SELF/kde/color-schemes" "$DST/.local/share/color-schemes" "color-schemes/"

# --- Terminal ---
cp_file "$SELF/terminal/kitty/kitty.conf" "$DST/.config/kitty/kitty.conf" "kitty/kitty.conf"
cp_dir "$SELF/terminal/btop" "$DST/.config/btop"   "btop/"
cp_dir "$SELF/terminal/cava" "$DST/.config/cava"   "cava/"

# --- Editors ---
cp_dir "$SELF/editors/nvim" "$DST/.config/nvim" "nvim/"
cp_dir "$SELF/editors/zed"  "$DST/.config/zed"  "zed/"

# --- Apps ---
cp_dir "$SELF/apps/fastfetch"  "$DST/.config/fastfetch"  "fastfetch/"
cp_dir "$SELF/apps/flameshot"  "$DST/.config/flameshot"  "flameshot/"
cp_dir "$SELF/apps/mpv"        "$DST/.config/mpv"        "mpv/"
cp_dir "$SELF/apps/lact"       "$DST/.config/lact"       "lact/"
cp_file "$SELF/apps/dconf/user" "$DST/.config/dconf/user" "dconf/user"
cp_dir "$SELF/apps/autostart"  "$DST/.config/autostart"  "autostart/"
cp_dir "$SELF/apps/session"    "$DST/.config/session"    "session/"
cp_file "$SELF/apps/mimeapps.list"   "$DST/.config/mimeapps.list"   "mimeapps.list"
cp_file "$SELF/apps/user-dirs.dirs"  "$DST/.config/user-dirs.dirs"  "user-dirs.dirs"
cp_file "$SELF/apps/user-dirs.locale" "$DST/.config/user-dirs.locale" "user-dirs.locale"

# --- Icons + обои ---
cp_dir "$SELF/icons"       "$DST/.icons"   ".icons/"
cp_dir "$SELF/wallpapers"  "$DST/Pictures" "wallpapers/"

# --- Cargo (если есть) ---
if [ -f "$SELF/dotfiles/cargo-config.toml" ]; then
  mkdir -p "$DST/.cargo"
  cp "$SELF/dotfiles/cargo-config.toml" "$DST/.cargo/config.toml" && echo "  OK cargo/config.toml"
fi

echo ""
echo "=============================================="
echo " ✅ ГОТОВО!"
echo "=============================================="
echo ""
echo "📦 Пакетов: ${#OFFICIAL_PKGS[@]} official + ${#AUR_PKGS[@]} AUR"
echo "   (шрифты: Cascadia Code, Hack, JetBrains Mono Nerd, Open Sans, Font Awesome)"
echo ""
echo "⚠️  Нюансы:"
echo "   • GTK4 symlinks ведут в /usr/share/themes/ — нужен catppuccin-gtk-theme-mocha (AUR)"
echo "   • Пропустить установку пакетов: ./install-configs.sh --no-pkgs"
echo "   • Весь builder можно скопировать на флешку и запустить на новой системе"
echo ""
