#!/usr/bin/env sh

killall waybar
waybar -c "$HOME"/.config/waybar/config-dp-1.jsonc & # waybar primary

killall swaybg
WALLPAPER=$(find ~/Pictures/Wallpapers/*/ -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
swaybg -m fill -i "$WALLPAPER"
