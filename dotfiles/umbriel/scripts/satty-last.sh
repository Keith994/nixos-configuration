#!/usr/bin/env bash
# 用 satty 标注截图目录里最新的一张图（umbriel 的 Mod+Shift+A）。
#
# 这个脚本是**原样复用** dotfiles/niri/scripts/satty-last.sh：它不依赖任何合成器 IPC，
# 只认 ~/Pictures/Screenshots 这个目录，所以 niri / umbriel 两个会话都能用同一份逻辑。
# （umbriel 侧没有 niri 的 screenshot-path 配置项，落盘位置由 noctalia 的截图 IPC 决定。）

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
