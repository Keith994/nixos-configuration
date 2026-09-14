#!/bin/bash

echo '5 minutes' > "$HOME/.local/state/idle-time";

lock="$HOME/.config/niri/scripts/lock.sh"
if [ ! -f $HOME/.local/state/idle-time ]; then
  # Default idle time
  echo "5 minutes" >$HOME/.local/state/idle-time
fi

# timeout 3600 'systemctl suspend'
idle_time=$(cat $HOME/.local/state/idle-time)
case $idle_time in
"5 minutes")
  swayidle -w \
    timeout 300 $lock \
    timeout 310 'niri msg action power-off-monitors' \
    before-sleep $lock
  ;;
"10 minutes")
  swayidle -w \
    timeout 600 $lock \
    timeout 610 'niri msg action power-off-monitors' \
    before-sleep $lock
  ;;
"20 minutes")
  swayidle -w \
    timeout 1200 $lock \
    timeout 1210 'niri msg action power-off-monitors' \
    before-sleep $lock
  ;;
"30 minutes")
  swayidle -w \
    timeout 1800 $lock \
    timeout 1810 'niri msg action power-off-monitors' \
    before-sleep $lock
  ;;
"infinity") ;;
*) ;;
esac
