#!/usr/bin/env bash
# 从 dotfiles/niri/scripts/float.sh 移植到 umbriel IPC（umbriel 的 Mod+F）。
#
# 语义：浮动 → 带缓冲地收回平铺（浏览器顺手拉回满宽）；平铺 → 浮到 60%x60% 并居中。
# 两个方向都短暂覆盖 windows_move：进入浮动从中央附近随机点 ease-out 落位，
# 回到平铺使用无随机的缩放收回；结束后恢复 animations.toml 的 spring + squash。

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/umbriel"
animation_override="$config_dir/float-animation.toml"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/umbriel-float-${UID}.lock"

# 防止按键连发让较早的进程提前删掉较晚进程仍在使用的临时动画配置。
exec 9>"$lock_file"
flock -n 9 || exit 0

focused="$(umbriel windows --json | jq -c '.[] | select(.focused == true and .active == true)' | head -1)"

# 没有聚焦窗口（例如焦点在图层表面上）就直接返回。
if [ -z "$focused" ]; then
  exit 0
fi

floating="$(jq -r '.floating' <<<"$focused")"
app_id="$(jq -r '.app_id' <<<"$focused")"
is_browser="$(grep -iE 'firefox|chromium|chrome|brave|vivaldi' <<<"$app_id" || true)"

disable_float_animation() {
  if [ -e "$animation_override" ]; then
    rm -f "$animation_override"
    umbriel msg config-reload >/dev/null
  fi
}

enable_float_animation() {
  local shader="$1"

  cat >"$animation_override" <<EOF
# 运行时临时文件：由 scripts/float.sh 生成并在动画结束后删除。
[animation.windows_move]
enabled = true
duration_ms = 550
curve = "easeout"
shader = "shaders/$shader"
EOF
  umbriel msg config-reload >/dev/null
  trap disable_float_animation EXIT HUP INT TERM
}

if [ "$floating" = "true" ]; then
  enable_float_animation "tile-return.glsl"

  umbriel msg window-toggle-floating
  if [ -n "$is_browser" ]; then
    umbriel msg window-set-primary-extent:1.0
  fi
else
  enable_float_animation "random-float.glsl"

  umbriel msg window-toggle-floating
  umbriel msg window-set-primary-extent:0.6
  umbriel msg window-set-secondary-extent:0.6
  umbriel msg window-center
fi

# 等专用动画完成再恢复常规 windows_move 配置。
sleep 0.40
