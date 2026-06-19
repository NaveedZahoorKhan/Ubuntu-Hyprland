#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Ensure weather cache is up-to-date before locking (Waybar/lockscreen readers)
bash "$HOME/.config/hypr/UserScripts/WeatherWrap.sh" >/dev/null 2>&1

if pidof hyprlock >/dev/null; then
  exit 0
fi

exec hyprlock -q --config "$HOME/.config/hypr/hyprlock.conf" --no-fade-in --grace 1
