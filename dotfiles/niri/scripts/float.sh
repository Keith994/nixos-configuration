#!/bin/env bash

window_focused=$(niri msg --json windows | jq -r '.[] | select(.is_focused == true)')
floating=$(echo "$window_focused" | jq -r '.is_floating')
is_app_id_null=$(echo "$window_focused" | jq -r '.app_id')
is_firefox=$(echo "$window_focused" | jq -r '.app_id' | grep -i 'firefox\|chromium\|chrome\|brave\|vivaldi')

if [ "$floating" = "true" ]; then
  niri msg action toggle-window-floating
  # niri msg action  center-window
  if [ "$is_firefox" != "" ]; then
    niri msg action set-window-width 100%
  fi
else
  niri msg action toggle-window-floating
  if [ "$is_app_id_null" != "null" ]; then
    niri msg action set-window-height 60%
    niri msg action set-window-width 60%
  fi
  niri msg action center-window
fi
