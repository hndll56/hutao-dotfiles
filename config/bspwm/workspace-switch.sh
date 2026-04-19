#!/bin/bash
bspc subscribe desktop_focus | while read -r event; do
    # Fade out semua window
    for win in $(bspc query -W -d focused); do
        xdotool windowfocus $win
    done
doneq
