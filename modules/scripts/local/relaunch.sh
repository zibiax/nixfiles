#!/usr/bin/env sh

qs kill
# Software rendering: needs no VRAM, so the bar and launcher keep working when
# a game has filled the GPU memory (they failed to create GL surfaces then)
QT_QUICK_BACKEND=software qs -d # bar, launcher, power menu and clipboard (~/.config/quickshell)

pkill -f "^swaybg " # the process is named .swaybg-wrapped on NixOS
WALLPAPER=$(find ~/Pictures/Wallpapers/*/ -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
swaybg -m fill -i "$WALLPAPER"
