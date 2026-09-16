#!/usr/bin/env bash
# 从 dotfiles/niri/scripts/lock.sh 移植过来（umbriel 的 Ctrl+Alt+L）。
#
# 差别：
# - niri 有 do-screen-transition（先做一个过渡动画再锁），umbriel 没有对应动作，去掉；
# - niri 的 power-off-monitors 换成 umbriel 的 dpms-off；
# - 锁屏本身仍然由 noctalia 负责（noctalia msg session lock），和 niri 会话用同一套锁屏。
# 另外 umbriel 会话在锁屏状态下 Mod+Escape（session-quit）会跳过确认直接退出，
# 这是上游行为，不是这里的问题。

set -euo pipefail

noctalia msg session lock
sleep 5s
umbriel msg dpms-off
