#!/usr/bin/env bash
# 用 satty 标注截图目录里最新的一张图（niri: Mod+Shift+A）。
#
# 为什么不在这里截图：这份配置刻意不引入 grim/slurp 那条 wlroots 工具链
# （见 AGENTS.md 第 8 节第 5 条）。区域/窗口/整屏截图走 niri 内置动作和 noctalia
# 的 IPC，落盘目录由 dotfiles/niri/config.kdl 的 screenshot-path 决定。
# satty 在这里只负责「打开已有的图来改」。

set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"

notify() {
  # noctalia 接管了 org.freedesktop.Notifications；没装 notify-send 也无所谓。
  noctalia msg notification-show satty "$1" >/dev/null 2>&1 || true
}

if [ ! -d "$dir" ]; then
  notify "截图目录不存在：$dir"
  exit 1
fi

# 文件名带空格（niri 的模板是 "Screenshot from ..."），所以整条链路按行处理，
# 不用 ls、不做 word splitting。
latest="$(
  find "$dir" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.ppm' \) \
    -printf '%T@ %p\n' 2>/dev/null |
    sort -rn | head -n1 | cut -d' ' -f2- || true
)"

if [ -z "$latest" ]; then
  notify "截图目录里还没有图片：$dir"
  exit 1
fi

exec satty --filename "$latest"
