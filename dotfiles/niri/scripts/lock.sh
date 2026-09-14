#!/bin/bash
niri msg action do-screen-transition --delay-ms 1000
dms ipc call lock lock
sleep 5s
niri msg action power-off-monitors
