#!/usr/bin/env bash
set -euo pipefail

VPN_CONNECTION="${VPN_CONNECTION:-fintua}"
WAYBAR_SIGNAL="${WAYBAR_SIGNAL:-8}"

json() {
  if command -v jq >/dev/null 2>&1; then
    jq -cn \
      --arg text "$1" \
      --arg tooltip "$2" \
      --arg class "$3" \
      --arg alt "$4" \
      '{text:$text, tooltip:$tooltip, class:$class, alt:$alt}'
  else
    printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' "$1" "$2" "$3" "$4"
  fi
}

profile_exists() {
  nmcli -t -f NAME,TYPE connection show | awk -F: -v vpn="$VPN_CONNECTION" '
    $1 == vpn && $2 == "vpn" { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

vpn_active() {
  nmcli -t -f NAME,TYPE connection show --active | awk -F: -v vpn="$VPN_CONNECTION" '
    $1 == vpn && $2 == "vpn" { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

refresh_waybar() {
  pkill "-RTMIN+$WAYBAR_SIGNAL" waybar >/dev/null 2>&1 || true
}

vpn_uuid() {
  nmcli -g connection.uuid connection show "$VPN_CONNECTION" 2>/dev/null | head -n 1
}

secret_lookup() {
  local uuid

  command -v secret-tool >/dev/null 2>&1 || return 1
  uuid="$(vpn_uuid)"
  [[ -n "$uuid" ]] || return 1

  secret-tool lookup hyprland-vpn "$uuid" connection "$VPN_CONNECTION" 2>/dev/null || true
}

secret_store() {
  local password="$1"
  local uuid

  command -v secret-tool >/dev/null 2>&1 || return 1
  uuid="$(vpn_uuid)"
  [[ -n "$uuid" ]] || return 1

  printf '%s' "$password" |
    secret-tool store --label="VPN $VPN_CONNECTION password" hyprland-vpn "$uuid" connection "$VPN_CONNECTION"
}

prompt_password() {
  command -v zenity >/dev/null 2>&1 || return 1
  zenity --password --title="VPN password: $VPN_CONNECTION"
}

maybe_store_secret() {
  local password="$1"

  command -v secret-tool >/dev/null 2>&1 || return 0
  command -v zenity >/dev/null 2>&1 || return 0

  if zenity --question \
    --title="Remember VPN password?" \
    --text="Save the $VPN_CONNECTION password in your login keyring for one-click connects?"; then
    if secret_store "$password"; then
      notify-send -u normal "VPN password saved" "$VPN_CONNECTION"
    else
      notify-send -u critical "VPN password was not saved" "The connection is active, but keyring storage failed."
    fi
  fi
}

short_error() {
  local output="$1"
  local message

  message="$(printf '%s\n' "$output" | awk '/^(Error|Warning):/ { line = $0 } END { print line }')"
  if [[ -z "$message" ]]; then
    message="$(printf '%s\n' "$output" | tail -n 1)"
  fi

  printf '%s' "${message:-$VPN_CONNECTION}"
}

needs_secret() {
  local output="$1"

  [[ "$output" == *"No valid secrets"* ]] ||
    [[ "$output" == *"vpn.secrets.password"* ]] ||
    [[ "$output" == *"failed to request VPN secrets"* ]]
}

connect_with_password() {
  local password="$1"
  local runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
  local safe_name="${VPN_CONNECTION//[^A-Za-z0-9_.-]/_}"
  local tmp
  local rc

  tmp="$(mktemp "$runtime_dir/vpn-$safe_name.XXXXXX")"
  chmod 600 "$tmp"
  printf 'vpn.secrets.password:%s\n' "$password" >"$tmp"

  nmcli --wait 60 connection up id "$VPN_CONNECTION" passwd-file "$tmp"
  rc=$?
  rm -f "$tmp"
  return "$rc"
}

connect_vpn() {
  local output
  local rc
  local password

  if output="$(nmcli --wait 60 connection up id "$VPN_CONNECTION" 2>&1)"; then
    notify-send -u normal "VPN connected" "$VPN_CONNECTION"
    return 0
  fi

  rc=$?
  if ! needs_secret "$output"; then
    notify-send -u critical "VPN connect failed" "$(short_error "$output")"
    return "$rc"
  fi

  password="$(secret_lookup || true)"
  if [[ -n "$password" ]]; then
    if output="$(connect_with_password "$password" 2>&1)"; then
      notify-send -u normal "VPN connected" "$VPN_CONNECTION"
      return 0
    fi
    rc=$?
  fi

  if ! password="$(prompt_password)"; then
    notify-send -u normal "VPN connect cancelled" "$VPN_CONNECTION"
    return 1
  fi

  if [[ -z "$password" ]]; then
    notify-send -u normal "VPN connect cancelled" "$VPN_CONNECTION"
    return 1
  fi

  if output="$(connect_with_password "$password" 2>&1)"; then
    notify-send -u normal "VPN connected" "$VPN_CONNECTION"
    maybe_store_secret "$password"
    return 0
  fi

  rc=$?
  notify-send -u critical "VPN connect failed" "$(short_error "$output")"
  return "$rc"
}

status() {
  if ! profile_exists; then
    json "VPN" "No VPN profile named '$VPN_CONNECTION'. Right click to open NetworkManager." "error" "missing"
    return 0
  fi

  if vpn_active; then
    local tooltip
    tooltip=$(printf 'Connected: %s\nLeft click: disconnect\nRight click: NetworkManager' "$VPN_CONNECTION")
    json "󰌾 VPN" "$tooltip" "connected" "connected"
  else
    local tooltip
    tooltip=$(printf 'Disconnected: %s\nLeft click: connect\nRight click: NetworkManager' "$VPN_CONNECTION")
    json "󰌿 VPN" "$tooltip" "disconnected" "disconnected"
  fi
}

toggle() {
  if ! profile_exists; then
    notify-send -u normal "VPN profile not found" "Create or rename a VPN profile to '$VPN_CONNECTION'."
    nm-connection-editor >/dev/null 2>&1 &
    return 1
  fi

  if vpn_active; then
    if nmcli connection down id "$VPN_CONNECTION"; then
      notify-send -u normal "VPN disconnected" "$VPN_CONNECTION"
    else
      notify-send -u critical "VPN disconnect failed" "$VPN_CONNECTION"
      return 1
    fi
  else
    connect_vpn || return 1
  fi

  refresh_waybar
}

case "${1:-status}" in
  status)
    status
    ;;
  toggle)
    toggle
    ;;
  *)
    echo "Usage: $0 [status|toggle]" >&2
    exit 2
    ;;
esac
