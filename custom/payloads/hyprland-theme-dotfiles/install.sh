#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/home"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$STATE_HOME/hyprland-theme-dotfiles/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$STAMP"
NO_LIVE_RELOAD=0

TARGETS=(
  ".config/hypr"
  ".config/waybar"
  ".config/rofi"
  ".config/wlogout"
  ".config/swaync"
  ".config/kitty"
  ".config/gtk-3.0"
  ".config/gtk-4.0"
  ".config/wallust"
  ".config/Kvantum"
  ".config/qt5ct"
  ".config/qt6ct"
  ".config/fastfetch"
  ".config/swappy"
  ".config/btop"
  ".config/cava"
  ".config/hyprrice/config.yaml"
  ".themes/Wal-GTK"
  ".themes/Wal-GTK-hdpi"
  ".themes/Flat-Remix-GTK-Blue-Dark"
  ".hyprrice/themes"
  ".hyprrice/.first_run"
  ".icons/catppuccin-frappe-maroon-cursors"
  ".icons/default/index.theme"
  ".local/bin/mpvpaper"
  ".local/bin/mpvpaper-holder"
  ".local/share/icons/kora"
  ".local/share/mpvpaper-deps"
  ".local/share/applications/hyprland-wallpaper-selector.desktop"
  ".local/share/applications/hyprrice.desktop"
  ".ssh/config"
  ".zshrc"
  "Pictures/wallpapers/Lady.png"
  "Pictures/wallpapers/jake-the-dog.960x540.mp4"
  "Pictures/wallpapers/Live-GIF/preview.gif"
)

usage() {
  cat <<'EOF'
Usage: ./install.sh [--no-live-reload]

Installs this Hyprland theme/dotfiles bundle into $HOME.
Existing target files are backed up first under:
  ~/.local/state/hyprland-theme-dotfiles/backups/<timestamp>

Options:
  --no-live-reload   Copy files only; do not call hyprctl, gsettings, or restart Waybar.
  -h, --help         Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --no-live-reload)
      NO_LIVE_RELOAD=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Missing source directory: $SRC_DIR" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required for install and backup." >&2
  exit 1
fi

backup_existing() {
  local rel="$1"
  local target="$HOME/$rel"

  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname -- "$rel")"
    rsync -a "$target" "$BACKUP_DIR/$(dirname -- "$rel")/"
  fi
}

echo "Creating backup: $BACKUP_DIR"
for rel in "${TARGETS[@]}"; do
  backup_existing "$rel"
done

echo "Installing files into $HOME"
rsync -a "$SRC_DIR"/ "$HOME"/

ensure_local_bin_path() {
  local zshrc="$HOME/.zshrc"
  local marker="# User-local applications installed outside apt/pacman."

  touch "$zshrc"
  if ! grep -Fq "$marker" "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# User-local applications installed outside apt/pacman.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
  fi
}

ensure_local_bin_path

# Keep active selector links portable after install.
ln -sfn "configs/[TOP] Default Laptop" "$HOME/.config/waybar/config"
ln -sfn "style/[Wallust] Simple.css" "$HOME/.config/waybar/style.css"
ln -sfn "../../Pictures/wallpapers/Lady.png" "$HOME/.config/rofi/.current_wallpaper"
ln -sfn "../../.themes/Wal-GTK/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
ln -sfn "../../.themes/Wal-GTK/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
ln -sfn "../../.themes/Wal-GTK/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"

if [[ "$NO_LIVE_RELOAD" -eq 0 ]]; then
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Flat-Remix-GTK-Blue-Dark' || true
    gsettings set org.gnome.desktop.interface icon-theme 'kora' || true
    gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-frappe-maroon-cursors' || true
    gsettings set org.gnome.desktop.interface cursor-size 24 || true
  fi

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
      HYPRCURSOR_THEME=catppuccin-frappe-maroon-cursors \
      HYPRCURSOR_SIZE=24 \
      XCURSOR_THEME=catppuccin-frappe-maroon-cursors \
      XCURSOR_SIZE=24 >/dev/null 2>&1 || true
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user set-environment \
      HYPRCURSOR_THEME=catppuccin-frappe-maroon-cursors \
      HYPRCURSOR_SIZE=24 \
      XCURSOR_THEME=catppuccin-frappe-maroon-cursors \
      XCURSOR_SIZE=24 >/dev/null 2>&1 || true
  fi

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl setcursor catppuccin-frappe-maroon-cursors 24 >/dev/null 2>&1 || true
    hyprctl reload >/dev/null 2>&1 || true
    if pgrep -x waybar >/dev/null 2>&1; then
      pkill -x waybar || true
      hyprctl dispatch exec waybar >/dev/null 2>&1 || true
    fi
  fi
fi

echo "Done."
echo "Backup saved at: $BACKUP_DIR"
