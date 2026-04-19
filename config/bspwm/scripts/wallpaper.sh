#!/bin/bash
# ─── Wallpaper & Pywal Integration ───────────────────
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Pilih wallpaper secara acak
WALL=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)

if [ -z "$WALL" ]; then
  echo "[ERROR] Tidak ada wallpaper di $WALLPAPER_DIR"
  exit 1
fi

# Generate color scheme dari wallpaper
wal -i "$WALL" --saturate 0.8 -q

# Set wallpaper via nitrogen
nitrogen --set-scaled "$WALL" --save

# Reload polybar agar warna ter-update
~/.config/polybar/launch.sh

# Reload dunst
pkill dunst && dunst &

# Reload bspwm borders
bspc wm -r

echo "[OK] Wallpaper: $(basename $WALL)"


