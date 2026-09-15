#!/bin/bash
niri msg action do-screen-transition --delay-ms 1000
noctalia msg session lock
sleep 5s
niri msg action power-off-monitors
