#!/usr/bin/env bash
# 从 dotfiles/niri/scripts/switch.sh 移植到 umbriel IPC。
#
# 用法不变：switch.sh <app_id> [启动命令]
#   已有匹配 app_id 的窗口 → 聚焦它（umbriel msg window-focus:<id>）
#   没有                    → 跑第二个参数启动
# 换掉的是取窗口列表的方式：niri msg --json windows → umbriel windows --json；
# 字段也变了（niri: is_focused/is_floating；umbriel: focused/floating），
# id 两边都是 ext-foreign-toplevel 的字符串标识。
# 注意：umbriel 的窗口列表只报 mapped 的窗口，托盘里隐藏的窗口不在此列。

set -euo pipefail

window_id="$(
  umbriel windows --json |
    jq -r --arg app "$1" '.[] | select(.app_id == $app) | .id' |
    head -1
)"

if [ -z "$window_id" ] || [ "$window_id" = "null" ]; then
  # 第二个参数是命令行，交给 shell 展开（niri 那版靠 word splitting，这里更明确）
  if [ -n "${2:-}" ]; then
    sh -c "$2" &
  fi
else
  umbriel msg "window-focus:$window_id"
fi
