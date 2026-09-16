#!/usr/bin/env bash

app_id=$(niri msg --json windows | jq -r --arg app "$1" '.[] | select(.app_id == $app) | .id' | head -1)

if [ -z "$app_id" ]; then
  [ -n "$2" ] && $2 &
else
  niri msg action focus-window --id "$app_id"
fi
