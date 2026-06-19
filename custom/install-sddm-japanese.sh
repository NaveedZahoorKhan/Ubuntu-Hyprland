#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_SRC="$ROOT_DIR/custom/payloads/sddm-astronaut-theme"
THEME_NAME="sddm-astronaut-theme"
THEME_DST="/usr/share/sddm/themes/$THEME_NAME"
ENABLE_SDDM=1

usage() {
  cat <<'EOF'
Usage: custom/install-sddm-japanese.sh [--no-enable]

Installs the bundled SDDM Astronaut theme and selects the Japanese aesthetic
variant. By default it enables sddm.service on systemd systems.

Options:
  --no-enable   Install/configure the theme but do not enable SDDM.
  -h, --help    Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --no-enable) ENABLE_SDDM=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -d "$THEME_SRC" ]]; then
  echo "Missing bundled SDDM theme: $THEME_SRC" >&2
  exit 1
fi

sudo -v

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sddm \
    libqt6svg6 \
    qt6-declarative-dev \
    qt6-svg-dev \
    qt6-virtualkeyboard-plugin \
    libqt6multimedia6 \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-effects \
    qml6-module-qtquick-virtualkeyboard \
    rsync
fi

stamp="$(date +%Y%m%d-%H%M%S)"
if [[ -e "$THEME_DST" ]]; then
  sudo mv "$THEME_DST" "${THEME_DST}.bak-$stamp"
fi

sudo mkdir -p "$(dirname -- "$THEME_DST")"
sudo rsync -a "$THEME_SRC"/ "$THEME_DST"/
sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/japanese_aesthetic.conf|' "$THEME_DST/metadata.desktop"

if [[ -d "$THEME_DST/Fonts" ]]; then
  sudo mkdir -p /usr/local/share/fonts/sddm-astronaut
  sudo rsync -a "$THEME_DST/Fonts"/ /usr/local/share/fonts/sddm-astronaut/
  fc-cache -f >/dev/null 2>&1 || true
fi

sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-japanese-hyprland-theme.conf >/dev/null <<EOF
[Theme]
Current=$THEME_NAME
EOF

sudo tee /etc/sddm.conf.d/20-japanese-hyprland-virtual-keyboard.conf >/dev/null <<'EOF'
[General]
InputMethod=qtvirtualkeyboard
EOF

if [[ "$ENABLE_SDDM" -eq 1 ]] && command -v systemctl >/dev/null 2>&1; then
  for manager in gdm.service gdm3.service lightdm.service lxdm.service; do
    sudo systemctl disable --now "$manager" >/dev/null 2>&1 || true
  done
  sudo systemctl set-default graphical.target
  sudo systemctl enable sddm.service
fi

echo "Installed SDDM Japanese aesthetic theme at $THEME_DST"
