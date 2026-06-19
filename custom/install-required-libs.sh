#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_FILE="$ROOT_DIR/custom/required-packages.txt"

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user; sudo is used only for package installation." >&2
  exit 1
fi

if ! command -v apt-cache >/dev/null 2>&1 || ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports Ubuntu/Debian apt systems." >&2
  exit 1
fi

sudo -v
sudo apt-get update

available=()
while IFS= read -r pkg; do
  pkg="${pkg%%#*}"
  pkg="${pkg//[$'\t\r\n ']}"
  [[ -z "$pkg" ]] && continue

  if apt-cache show "$pkg" >/dev/null 2>&1; then
    available+=("$pkg")
  else
    echo "Skipping unavailable package: $pkg"
  fi
done < "$PKG_FILE"

if ((${#available[@]})); then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${available[@]}"
fi

echo "Custom package layer complete."
