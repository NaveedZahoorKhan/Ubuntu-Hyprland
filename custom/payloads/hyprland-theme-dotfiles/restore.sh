#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$STATE_HOME/hyprland-theme-dotfiles/backups"

usage() {
  cat <<'EOF'
Usage: ./restore.sh [backup-directory]

Restores a backup created by install.sh or backup.sh.
If no backup directory is supplied, the newest backup in
~/.local/state/hyprland-theme-dotfiles/backups is used.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required for restore." >&2
  exit 1
fi

BACKUP_DIR="${1:-}"
if [[ -z "$BACKUP_DIR" ]]; then
  if [[ ! -d "$BACKUP_ROOT" ]]; then
    echo "No backup root found: $BACKUP_ROOT" >&2
    exit 1
  fi
  BACKUP_DIR="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
fi

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
  echo "Backup directory not found: ${BACKUP_DIR:-<none>}" >&2
  exit 1
fi

echo "Restoring from: $BACKUP_DIR"
rsync -a "$BACKUP_DIR"/ "$HOME"/

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "Restore complete."
