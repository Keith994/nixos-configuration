#!/usr/bin/env bash
# 视频壁纸开关（niri: Mod+Shift+W）。
#
# mpvpaper 只往 layer-shell 的 background 层画视频，这里把它当**手动**工具用：
# noctalia 自己也在管壁纸，两边同时画谁在上取决于层序，所以刻意不写
# spawn-at-startup（理由写在 AGENTS.md 第 8 节第 20 条）。按一下开、再按一下关。
#
# 视频从 $MPVPAPER_DIR（默认 ~/Videos/wallpapers）里随机取一个；
# 想只给某个输出放就 MPVPAPER_OUTPUT=DP-1，默认 ALL（所有输出）。
# 另外 mpvpaper 还会读 ~/.config/mpvpaper/{pauselist,stoplist}：把程序名写进去，
# 那些程序一跑起来就自动暂停/停掉视频（比 -p 的「被全屏盖住才暂停」更可靠）。

set -euo pipefail

dir="${MPVPAPER_DIR:-$HOME/Videos/wallpapers}"
output="${MPVPAPER_OUTPUT:-ALL}"

notify() {
  # noctalia 接管了 org.freedesktop.Notifications；没装 notify-send 也无所谓。
  noctalia msg notification-show mpvpaper "$1" >/dev/null 2>&1 || true
}

# 已经在跑就只做「关」这一步：mpvpaper -f 之后自己 daemon 化、没有 pidfile，
# 只能按进程名收；它收到 SIGTERM 会连带把自己的 mpv 子进程一起处理掉。
# pgrep/pkill 来自 pkgs.procps（modules/home/media.nix 显式装的，不靠系统闭包碰巧有）。
if pgrep -x mpvpaper >/dev/null 2>&1; then
  pkill -x mpvpaper || true
  notify "视频壁纸已关闭"
  exit 0
fi

if [ ! -d "$dir" ]; then
  notify "视频壁纸目录不存在：$dir"
  exit 1
fi

# 文件名可能带空格，所以 -print0 + mapfile，不做 word splitting。
mapfile -d '' videos < <(
  find "$dir" -maxdepth 1 -type f \
    \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) \
    -print0 2>/dev/null
)

if [ "${#videos[@]}" -eq 0 ]; then
  notify "目录里没有视频文件：$dir"
  exit 1
fi

video="${videos[RANDOM % ${#videos[@]}]}"

# -f  fork 出去（niri 的 spawn-sh 不等它），-p 被全屏窗口盖住时暂停省 CPU；
# -o 里 loop 循环播放、no-audio 别出声，hwdec=auto 能硬解就硬解。
# 失败（比如不是在 Wayland 会话里）会让 set -e 直接退出，不会误报成功。
mpvpaper -f -p -o "no-audio loop hwdec=auto" "$output" "$video"

notify "视频壁纸已开启：$(basename "$video")"
