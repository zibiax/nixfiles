#!/usr/bin/env sh

qs kill
qs -d # bar, launcher, power menu and clipboard (~/.config/quickshell)

killall swaybg
WALLPAPER=$(find ~/Pictures/Wallpapers/*/ -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
swaybg -m fill -i "$WALLPAPER"
