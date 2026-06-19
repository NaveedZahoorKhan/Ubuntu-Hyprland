# Hyprland Theme Dotfiles

Portable snapshot of the current Hyprland setup for user `icarus`.

This bundle is based on the JaKooLit Ubuntu Hyprland layout, with the local fixes applied for:

- working JaKooLit-style Hyprland source layout
- clean top Waybar using `[TOP] Default Laptop`
- Super key opening Rofi app launcher
- Snap desktop entries visible in launchers
- wallpaper selector desktop entry
- current static wallpaper and optional live GIF asset
- reliable `swww` startup for static and animated wallpapers
- current GTK theme and icon theme assets
- Catppuccin Frappe Maroon cursor across Hyprland, XWayland, GTK 3, and GTK 4
- HyprRice GUI config, desktop launcher, bundled themes, and local safety patches
- SSH agent environment startup and SSH host config for Bitbucket/GitHub key selection
- Waybar VPN toggle with first-connect password prompt and optional login-keyring storage
- active-window opacity controls
- visible Waybar HINT button and updated quick cheat sheet
- user-local mpvpaper install with live wallpaper helper

## Install

From this directory:

```bash
./install.sh
```

For the HyprRice GUI on a fresh restore, install the user-local Python app after the dotfiles:

```bash
./install-hyprrice.sh
```

That script clones HyprRice into `~/.local/src/HyprRice`, creates a venv at
`~/.local/share/hyprrice-venv`, links `~/.local/bin/hyprrice`, and applies the
local compatibility/safety patch in `patches/hyprrice-local-fixes.patch`.

The installer backs up existing target files first under:

```text
~/.local/state/hyprland-theme-dotfiles/backups/<timestamp>
```

For a copy-only install without live Hyprland/Waybar reload:

```bash
./install.sh --no-live-reload
```

## Restore

Restore the latest backup:

```bash
./restore.sh
```

Restore a specific backup:

```bash
./restore.sh ~/.local/state/hyprland-theme-dotfiles/backups/<timestamp>
```

## Manual Backup

Create a backup without installing:

```bash
./backup.sh
```

## Dependency Check

```bash
./check-deps.sh
```

The script reports required and optional commands. It does not install packages.

## Packaged Paths

The install payload lives under `home/` and is copied into `$HOME`.

Main paths included:

- `.config/hypr`
- `.config/waybar`
- `.config/rofi`
- `.config/wlogout`
- `.config/swaync`
- `.config/kitty`
- `.config/wallust`
- `.config/Kvantum`
- `.config/qt5ct`
- `.config/qt6ct`
- `.config/gtk-3.0`
- `.config/gtk-4.0`
- `.config/hyprrice/config.yaml`
- `.themes/Wal-GTK`
- `.themes/Wal-GTK-hdpi`
- `.themes/Flat-Remix-GTK-Blue-Dark`
- `.hyprrice/themes`
- `.icons/catppuccin-frappe-maroon-cursors`
- `.icons/default/index.theme`
- `.local/bin/mpvpaper`
- `.local/bin/mpvpaper-holder`
- `.local/share/icons/kora`
- `.local/share/mpvpaper-deps`
- `.local/share/applications/hyprland-wallpaper-selector.desktop`
- `.local/share/applications/hyprrice.desktop`
- `.ssh/config`
- `.zshrc`
- `Pictures/wallpapers/Lady.png`
- `Pictures/wallpapers/jake-the-dog.960x540.mp4`
- `Pictures/wallpapers/Live-GIF/preview.gif`

The full `Pictures/wallpapers` folder was not bundled because it is over 1 GB. This package includes the current wallpaper, a small mpvpaper sample video, and the live GIF asset only.

Private SSH keys are not bundled. The package includes only SSH client config so restored systems can choose the intended already-installed keys and use the desktop SSH agent.

## Notes

Active links are stored as portable relative symlinks:

- `.config/waybar/config -> configs/[TOP] Default Laptop`
- `.config/waybar/style.css -> style/[Wallust] Simple.css`
- `.config/rofi/.current_wallpaper -> ../../Pictures/wallpapers/Lady.png`
- `.config/gtk-4.0/gtk.css -> ../../.themes/Wal-GTK/gtk-4.0/gtk.css`
- `.config/gtk-4.0/gtk-dark.css -> ../../.themes/Wal-GTK/gtk-4.0/gtk-dark.css`
- `.config/gtk-4.0/assets -> ../../.themes/Wal-GTK/gtk-4.0/assets`

HyprRice writes live Hyprland changes only to:

```text
~/.config/hypr/UserConfigs/HyprRiceGenerated.conf
```

The root `~/.config/hypr/hyprland.conf` remains the JaKooLit-style sourced entrypoint.

The installer also reapplies:

```text
GTK_THEME=Flat-Remix-GTK-Blue-Dark
ICON_THEME=kora
HYPRCURSOR_THEME=catppuccin-frappe-maroon-cursors
HYPRCURSOR_SIZE=24
XCURSOR_THEME=catppuccin-frappe-maroon-cursors
XCURSOR_SIZE=24
```

For Git over SSH, Hyprland starts `~/.config/hypr/UserScripts/StartCredentialEnv.sh`. It exports the active SSH agent socket to systemd, DBus, Hyprland-spawned apps, and fresh shells. Existing apps launched before this environment is set may need to be restarted once.

For the Waybar VPN button, the `fintua` NetworkManager profile is expected. If NetworkManager has no saved VPN secret, the first left click opens a password prompt. After a successful connection you can save the password in the login keyring so future clicks connect without another prompt. The password is not included in this bundle.

Active-window opacity shortcuts:

- `Super+Alt+-`: reduce active window opacity
- `Super+Alt+=`: increase active window opacity
- `Super+Alt+0`: reset active window opacity

Hints and keybinds:

- `Super+H`: quick cheat sheet
- `Super+Shift+K`: searchable keybinds
- `HINT` on the top bar: left click for quick cheat sheet, right click for searchable keybinds

mpvpaper live wallpaper:

- `Super+Alt+W`: start mpvpaper or cycle to the next video in `~/Videos/Hidamari`
- `Super+Alt+N`: next video in `~/Videos/Hidamari`
- `Super+Alt+P`: previous video in `~/Videos/Hidamari`
- `Super+Alt+Shift+W`: stop mpvpaper and restore swww
- `~/.config/hypr/UserScripts/MpvpaperLive.sh start /path/to/video.mp4`: start a specific video wallpaper
- `~/.config/hypr/UserScripts/MpvpaperLive.sh next`: cycle to the next video
- `~/.config/hypr/UserScripts/MpvpaperLive.sh stop`: stop mpvpaper and restore swww

`mpvpaper` was built user-locally from the 1.8 release and is bundled with the local `libmpv` runtime it was linked against. No sudo install is required for restore on this system layout.
The Hidamari video folder itself is not bundled because it is about 801 MB; keep videos under `~/Videos/Hidamari` or set `MPVPAPER_VIDEO_DIR=/path/to/videos`.
Videos are started with `panscan=1.0` so they fill the screen; wide or tall videos may be cropped at the edges instead of letterboxed.
