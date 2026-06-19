# Japanese Hyprland One-Click Installer

This fork keeps the JaKooLit Ubuntu Hyprland `25.10` base and adds a custom
installer layer for the current local setup.

## One-Click Install

```bash
chmod +x install-japanese-hyprland.sh
./install-japanese-hyprland.sh
```

Useful variants:

```bash
./install-japanese-hyprland.sh --custom-only
./install-japanese-hyprland.sh --no-sddm-enable
./install-japanese-hyprland.sh --skip-hyprrice
./install-japanese-hyprland.sh --use-icarus-monitor-profile
```

## Included Custom Layer

- Current Hyprland, Waybar, Rofi, SwayNC, Wlogout, Kitty, GTK, Kvantum, qt5ct,
  qt6ct, Wallust, Fastfetch, Swappy, Btop, and Cava dotfiles.
- Fixed Hyprland source layout and verified `hyprland.conf` entrypoint.
- Clean top Waybar layout using `[TOP] Default Laptop` and `[Wallust] Simple`.
- Super key Rofi launcher, visible `HINT` button, updated hints, screenshot
  bindings, opacity shortcuts, VPN button, SSH-agent startup, and Snap app
  launcher fixes.
- `swww` wallpaper startup and `mpvpaper` live wallpaper helper.
- User-local `mpvpaper` binary plus the local `libmpv` runtime it was built
  against.
- Optional `icarus-dual-display` Hyprland monitor profile for the local
  eDP-1 + HDMI-A-1 setup.
- SDDM Astronaut theme bundled locally, configured to
  `Themes/japanese_aesthetic.conf`.
- Extra package list in `custom/required-packages.txt`.

## Layout

```text
install-japanese-hyprland.sh
custom/
  apply-dotfiles.sh
  install-required-libs.sh
  install-sddm-japanese.sh
  required-packages.txt
  payloads/
    hyprland-theme-dotfiles/
    sddm-astronaut-theme/
```

Private SSH keys and VPN passwords are intentionally not included.
