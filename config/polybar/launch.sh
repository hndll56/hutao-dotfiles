#!/usr/bin/env bash

dir="$HOME/.config/polybar"
themes=(`ls --hide="launch.sh" $dir`)

launch_bar() {
	# Terminate already running bar instances
	killall -q polybar

	# Wait until the processes have been shut down
	while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

	# Launch the bar
	polybar -q hutao-main -c "$dir/config.ini" &
}

if [[ "$1" == "--hutao" ]]; then
	launch_bar
elif [[ "$1" == "--gruvbox" ]]; then
	dir="$HOME/.config/polybar"
	theme="gruvbox"
	# Terminate already running bar instances
	killall -q polybar

	# Wait until the processes have been shut down
	while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

	# Launch the bar
	polybar -q gruvbox-main -c "$dir/$theme/config.ini" &
else
	cat <<- EOF
	Usage : launch.sh --hutao|--gruvbox
	EOF
fi
