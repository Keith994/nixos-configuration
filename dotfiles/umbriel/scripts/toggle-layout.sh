#!/usr/bin/env bash
# 在 scrolling ⇄ dwindle 之间切换「当前工作区」的布局（umbriel 的 Mod+D）。
#
# 为什么不用内置动作 workspace-set-layout:toggle：
# 那个是三态循环 —— scrolling → dwindle → master → scrolling，
# 按两下 Mod+D 会停在用户没要的 master 上。这里读一次 IPC 自己判断，
# 保证按两下一定回到原点（如果是别的途径切到了 master，下一按先去 dwindle）。
# 想要三态循环的话，把这个键位直接换成 "workspace-set-layout:toggle" 即可。
#
# 判据是 workspaces --json 里 focused=true 的那条：源码里 workspace-set-layout
# 作用的就是「preferred（指针所在）输出的活动工作区」，
# 和 focused 的定义一模一样（src/server/actions.cpp 的 activeWorkspace()）。

set -euo pipefail

current="$(
  umbriel workspaces --json |
    jq -r '.[] | select(.focused) | .layout' |
    head -1
)"

case "$current" in
  dwindle) umbriel msg workspace-set-layout:scrolling ;;
  scrolling) umbriel msg workspace-set-layout:master ;;
  master) umbriel msg workspace-set-layout:dwindle ;;
  *) : ;; # 读不到（没有输出 / 没有活动工作区）就什么都不做
esac
