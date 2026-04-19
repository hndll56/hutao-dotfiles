#!/bin/bash
current_workspaces=$(bspc query -D --names | wc -l)

if [ "$current_workspaces" -gt 3 ]; then
    bspc monitor -d I II III
else
    bspc monitor -d I II III IV V VI VII VIII IX X
fi
