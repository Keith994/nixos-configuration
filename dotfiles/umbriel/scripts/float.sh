#!/usr/bin/env bash
# 从 dotfiles/niri/scripts/float.sh 移植到 umbriel IPC（umbriel 的 Mod+F）。
#
# 换掉的东西：
#   niri msg --json windows  →  umbriel windows --json
#   字段 is_focused/is_floating/app_id  →  focused/floating/app_id（id 仍是字符串）
#   niri msg action ...      →  umbriel msg <action>
# 语义保持一样：浮动 → 贴回平铺（浏览器顺手拉回满宽）；平铺 → 浮到 60%x60% 并居中。

set -euo pipefail

focused="$(umbriel windows --json | jq -c '.[] | select(.focused == true)' | head -1)"

# 没有聚焦窗口（例如焦点在图层表面上）就直接返回
if [ -z "$focused" ]; then
  exit 0
fi

floating="$(jq -r '.floating' <<<"$focused")"
app_id="$(jq -r '.app_id' <<<"$focused")"
is_browser="$(grep -iE 'firefox|chromium|chrome|brave|vivaldi' <<<"$app_id" || true)"

if [ "$floating" = "true" ]; then
  umbriel msg window-toggle-floating
  if [ -n "$is_browser" ]; then
    umbriel msg window-set-width:1.0
  fi
else
  umbriel msg window-toggle-floating
  if [ -n "$app_id" ]; then
    umbriel msg window-set-height:0.6
    umbriel msg window-set-width:0.6
    umbriel msg window-center
  fi
fi
