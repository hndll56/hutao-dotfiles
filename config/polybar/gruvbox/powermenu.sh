#!/usr/bin/env bash

# Simple powermenu using rofi
chosen=$(echo -e " Lock\n Logout\n Reboot\n Shutdown" | rofi -dmenu -i -p "POWER MENU" -theme-str '
    window { width: 200px; }
    listview { lines: 4; }
    element { padding: 5px; }
    textbox { colors: [ "#ebdbb2", "#282828" ]; }
')

case "$chosen" in
    *"Lock")   betterlockscreen -l ;;
    *"Logout") bspc quit ;;
    *"Reboot") systemctl reboot ;;
    *"Shutdown") systemctl poweroff ;;
esac