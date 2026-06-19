#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland"
log_file="$log_dir/credential-env.log"
mkdir -p "$log_dir"

find_agent_socket() {
  local candidates=(
    "$runtime_dir/gcr/ssh"
    "$runtime_dir/openssh_agent"
    "$runtime_dir/gnupg/S.gpg-agent.ssh"
  )

  local socket
  for socket in "${candidates[@]}"; do
    if [[ -S "$socket" ]]; then
      printf '%s\n' "$socket"
      return 0
    fi
  done

  return 1
}

socket=""
for _ in {1..20}; do
  if socket="$(find_agent_socket)"; then
    break
  fi
  sleep 0.25
done

if [[ -z "$socket" ]]; then
  echo "$(date -Is) no SSH agent socket found" >>"$log_file"
  exit 0
fi

export SSH_AUTH_SOCK="$socket"

systemctl --user set-environment "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >/dev/null 2>&1 || true
dbus-update-activation-environment --systemd SSH_AUTH_SOCK >/dev/null 2>&1 || true
hyprctl keyword env "SSH_AUTH_SOCK,$SSH_AUTH_SOCK" >/dev/null 2>&1 || true

echo "$(date -Is) SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>"$log_file"
