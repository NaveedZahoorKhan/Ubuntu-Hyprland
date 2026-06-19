#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${HYPRRICE_REPO_URL:-https://github.com/alderman-norta92/HyprRice.git}"
HYPRRICE_REF="${HYPRRICE_REF:-81c3c765f060c3c9d484a2b700cadf2cebf28b71}"
SRC_DIR="${HYPRRICE_SRC_DIR:-$HOME/.local/src/HyprRice}"
VENV_DIR="${HYPRRICE_VENV_DIR:-$HOME/.local/share/hyprrice-venv}"
PATCH_FILE="$ROOT_DIR/patches/hyprrice-local-fixes.patch"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd git
need_cmd python3

mkdir -p "$(dirname -- "$SRC_DIR")" "$HOME/.local/bin"

if [[ ! -d "$SRC_DIR/.git" ]]; then
  git clone "$REPO_URL" "$SRC_DIR"
  git -C "$SRC_DIR" checkout "$HYPRRICE_REF"
else
  echo "Using existing HyprRice source: $SRC_DIR"
fi

if [[ -f "$PATCH_FILE" ]]; then
  if git -C "$SRC_DIR" apply --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
    echo "HyprRice local fixes are already applied."
  elif git -C "$SRC_DIR" apply --check "$PATCH_FILE" >/dev/null 2>&1; then
    git -C "$SRC_DIR" apply "$PATCH_FILE"
    echo "Applied HyprRice local fixes."
  else
    echo "Warning: local HyprRice patch did not apply cleanly. Continuing with source as-is." >&2
  fi
fi

python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip wheel setuptools
"$VENV_DIR/bin/python" -m pip install -e "$SRC_DIR" requests

ln -sfn "$VENV_DIR/bin/hyprrice" "$HOME/.local/bin/hyprrice"

if [[ -f "$ROOT_DIR/home/.local/share/applications/hyprrice.desktop" ]]; then
  install -Dm644 \
    "$ROOT_DIR/home/.local/share/applications/hyprrice.desktop" \
    "$HOME/.local/share/applications/hyprrice.desktop"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

echo "HyprRice installed at: $VENV_DIR"
echo "Run: hyprrice gui"
