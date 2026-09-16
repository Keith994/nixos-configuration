# Umbriel 测试会话（从 niri 翻译来的配置）

Umbriel 是 [noctalia-dev/umbriel](https://github.com/noctalia-dev/umbriel)——Noctalia 官方的
wlroots 合成器（C++23 + wlroots 0.20 + 自己的 scenefx 分支），配置是 TOML，和 niri 的 KDL
是两套东西。这里的做法是**逐条翻译** niri 配置，而不是共享同一份文件。

- **只当额外可选的测试会话**：greetd 的 `session.default` 仍然是 `niri`，
  登录页 picker 里会多出一个 "Umbriel"，不选它就完全等于以前。
- niri + Noctalia v5 那条链路**一个字节都没改**（只往两个 `imports` 列表里各加了一行）。
- 上游自己声明过：umbriel 还年轻，键名/键位/行为都可能随版本变，默认值是"观点"不是"契约"。

相关文件：

| 文件 | 作用 |
| --- | --- |
| `flake.nix` | 加 `umbriel` 输入（`git+https`，见下面第 5 节说明） |
| `flake.lock` | 只新增了 umbriel 相关节点，没有动已有输入 |
| `modules/nixos/umbriel.nix` | 装包 + 注册会话 + portal（纯增量） |
| `modules/home/umbriel.nix` | `~/.config/umbriel` → 仓库目录的 out-of-store 软链 |
| `dotfiles/umbriel/*.toml` | 配置本体（见第 2 节对照表） |
| `dotfiles/umbriel/scripts/*.sh` | 从 `dotfiles/niri/scripts/` 移植过来的脚本 |

## 1. 怎么用

```bash
# 首次会很慢：umbriel 和 xdg-desktop-portal-umbriel 都没有 cachix，要本地编译
sudo nixos-rebuild switch --flake ~/nix-config#nixos-adol

# 登录页（noctalia-greeter）的会话 picker 里选 "Umbriel"
# 或者从 TTY 手动起：
start-umbriel

# 已经在图形会话里想先开个嵌套窗口试试（默认 Mod 会变成 Alt）：
umbriel

# 校验配置（不需要跑会话）——改了 dotfiles/umbriel/*.toml 之后先跑这个
umbriel validate -c ~/.config/umbriel/config.toml

# 日志
less ~/.cache/umbriel/umbriel.log
```

配置是**热重载**的：改 `dotfiles/umbriel/*.toml` 保存即生效（`~/.config/umbriel` 是
out-of-store 软链，见第 5 节），不用 rebuild、也不用重开会话。但 `[general]`/`[environment]`
里标了"需要重启"的项除外。

退出测试会话：`Mod+Escape`（umbriel 内置的退出确认框）或 `Ctrl+Alt+Delete` 走 noctalia 会话面板。

## 2. 文件对照表

| niri（KDL） | umbriel（TOML） | 说明 |
| --- | --- | --- |
| `config.kdl` | `config.toml` | 常规 / 环境 / 工作区 / 外观 / 输入 / 布局 / 动画 / 热区 |
| `monitors.kdl` | `outputs.toml` | 连接器名和模式逐个搬 |
| `keys.kdl` | `keybinds.toml` | **全量**翻译（见第 3 节第 2 条） |
| `rules.kdl` + `noctalia.kdl` + `layouts.kdl` 的 `layer-rule` | `rules.toml` | 窗口规则 + 图层规则 |
| `machine-custom.kdl` | `machine-custom.toml`（可选 include） | 机器特有覆盖，缺文件不报错 |
| —（niri 没有对应物） | `noctalia.toml` | 仓库里先放的一份"只有注释"的占位；noctalia 主题模板会**覆盖**它，见第 5 节 |
| `scripts/satty-last.sh` | `scripts/satty-last.sh` | **原样复用**，它不碰合成器 IPC |
| `scripts/lock.sh` / `float.sh` / `switch.sh` | 同名脚本 | 逻辑照搬，IPC 换成 umbriel，见第 4 节 |
| —（niri 没有对应物） | `scripts/toggle-layout.sh` | `Mod+D` 切 dwindle ⇄ scrolling，见下面「与 niri 键位的唯一差异」 |

### 与 niri 键位的唯一差异

- **`Mod+D`**：niri 那边是"切换或启动 DBeaver"，这里改成**当前工作区在 `dwindle` ⇄ `scrolling`
  之间切换**（`scripts/toggle-layout.sh`）；DBeaver 挪到了 `Mod+Shift+D`。要换回去就把这两条对调。
- 为什么用脚本而不是内置动作：`workspace-set-layout:toggle` 是**三态循环**
  （scrolling → dwindle → master → scrolling），按两下 `Mod+D` 会停在用户没要的 `master` 上。
  脚本先用 `umbriel workspaces --json` 读一次当前布局，再显式设目标，保证两态来回。
  想要三态就在 `keybinds.toml` 里把这条换成 `"workspace-set-layout:toggle"`（连 jq 都不用了）。
- 判据用 `workspaces --json` 里 `focused = true` 的那条：源码里 `workspace-set-layout` 作用的是
  「preferred（指针所在）输出的活动工作区」（`src/server/actions.cpp` 的 `activeWorkspace()`），
  和 `focused` 的定义完全一致。
- 布局是**按工作区**记的（动作写的是该工作区的 layout override），切工作区互不影响；
  也可以用 `[[workspace]]` 规则给某个工作区固定布局（本配置没用）。
- niri 只有一种平铺布局，所以这条键位在 niri 侧没有任何对应物。

## 3. 不兼容清单（重点）

### 3.1 结构性的，绕不过去

1. **KDL → TOML**：语法不通，键名也从 kebab/camel 变成 snake_case（`open-floating` →
   `default_floating`、`open-on-workspace` → `default_workspace`）。所以是翻译，不是复用同一份文件。
2. **keybinds 是"替换"不是"增量"**：umbriel 只要配了 `[keybinds]`，整套内置键位就被丢掉。
   所以 `keybinds.toml` 必须把要保留的每一条都写出来，少写一条等于删掉一条。
   内置的 `Mod+Escape`（退出）、`Mod+F1`（循环焦点）、scratchpad 那几条等，都在这里被替换掉了。
3. **工作区模型不同**：
   - niri：`rules.kdl` 里 `workspace "1"/"2"/"3"` 是**永远存在**的命名工作区（钉在 eDP-1），
     其余按索引动态创建 —— 所以 `Mod+4` / `Mod+5` 在内屏也能用（创建出来的 4/5 号）。
   - umbriel：每个 output 要么是动态清单，要么是**精确**的静态名字清单。这里 eDP-1 用了
     `workspaces = [ "1", "2", "3" ]`，于是**内屏上 `Mod+4`/`Mod+5` 会报"没有这个工作区"**
     （等于没反应，无害）；HDMI-A-1 没写 `workspaces`，仍是动态，`Mod+4/5` 在外屏正常。
     想补齐就把 `"4", "5"` 加进 `outputs.toml` 的 eDP-1 清单。
   - 窗口规则里的 `default_workspace = "2"` / `"3"` 匹配的是**名字**，不受影响。
4. **窗口规则的匹配语义**：umbriel 一条规则里 `match.app_id` 和 `match.title` 之间是 **AND**，
   而 niri 的多个 `match` 行是 **OR**。所以 niri 里"一个规则堆 4 个 matcher"必须拆成多条规则
   （`rules.toml` 里已经拆开并标了注释）。另外 umbriel **没有否定匹配**（niri 的 `exclude`）。
5. **`[environment]` 的保留变量**：`XDG_SESSION_TYPE`、`XDG_CURRENT_DESKTOP`、
   `XDG_SESSION_DESKTOP`、`WAYLAND_DISPLAY`、`WAYLAND_SOCKET`、`DISPLAY`、`UMBRIEL_SOCKET`
   由 umbriel 自己 `setenv`（源码 `src/server/server.cpp`），写在配置里会被忽略甚至报错。
   → niri `environment.kdl` 里的 `XDG_SESSION_TYPE "wayland"` 在 umbriel 侧**删掉了**，
   其余（`QT_QPA_PLATFORMTHEME`/`XMODIFIERS`/`LANG`/`MOZ_*`/`no_proxy`）照搬。
6. **工作区轴向**：`workspace_axis` 默认 `"vertical"`（工作区竖排、列横向滚动）正好等于 niri
   的横向列布局，所以这一项刻意没写；写成 `"horizontal"` 就变了另一套东西。

### 3.2 有替代但不等价（近似值）

| niri | umbriel 这里的写法 | 差异 |
| --- | --- | --- |
| `gaps 0.5` | `layout.gap = 1` | umbriel 的 gap 是整数像素，四舍五入 |
| `preset-window-heights { 0.333/0.5/1.0 }` | 无 | `width_presets` 宽/高**共用**一个列表，没法单独给高度预设 |
| `switch-preset-column-width` | `window-cycle-width` | 等价（都走 `width_presets`，现在是 0.5/1.0） |
| `accel-speed 0.2` | `input.touchpad.sensitivity = 0.2` | 近似映射，手感自己再调 |
| `scroll-method "two-finger"` | 无 | 用 libinput 默认值 |
| `warp-mouse-to-focus` | `input.cursor.follows_focus = true` | umbriel 在跨输出移动/激活时也会 warp，范围略大 |
| `clipboard { disable-primary; }` | `input.middle_click_paste = false` | 只关"中键粘贴"，不等于整个禁用 primary selection |
| `debug.honor-xdg-activation-with-invalid-serial` | `general.focus_on_activate = false` | 目的相同（noctalia 通知按钮把窗口点出来），机制不同；**点了通知不聚焦就把它改成 `true`** |
| `center-visible-columns`（Mod+Shift+C） | `window-center` | umbriel 没有"可见列整体居中"，只能居中浮动窗口 |
| `screenshot-path` + 内置截图动作 | 无 | 见 3.3 |
| shadow `softness 40` / `spread 5` / `color "#0007"` | `softness = 40`（其余无） | softness 语义不同（niri 的长度 vs umbriel 0-200 的高斯 sigma），`spread` 无对应键，颜色用 umbriel 默认 `#0000007F`，观感略有差别 |
| 浮动窗口 `focus-ring` 渐变（`active-gradient`） | 无 | umbriel 只有全局 `colors.border.*` 单色 |
| 每条规则的 `geometry-corner-radius 12` / `clip-to-geometry` / `draw-border-with-background` | 全局 `appearance.corner_radius = 12` | 只能全局设 |
| `layer-rule place-within-backdrop`（noctalia-backdrop） | 无 | umbriel 的 layer rule 没有这个键；`noctalia-backdrop` 交给 noctalia 自己画 |
| `^quickshell$` / `^notifications$` / `^launcher$` 的 layer-rule | 无 | 那是 dms/noctalia v4 时代的 namespace，noctalia v5 不再用；现在由 `rules.toml` 里 `^noctalia-*` 那条覆盖 |
| 动画 spring（`damping-ratio`/`stiffness`） | `curve = "spring:1,800"` 等 | 能一一对应；但 niri 的 `horizontal-view-movement`、`config-notification`、`exit-confirmation`、`screenshot-ui` 在 umbriel 没有独立事件，`ease-out-expo/quad` 用内置 `easeout` 近似 |
| `gestures { hot-corners { off } }` | 四个 `[hot_corners.*] enabled = false` | umbriel 打包示例默认开左上角，这里显式全关 |
| `Mod+A` overview | `overview-toggle` | 等价（`[overview]` 其余保持默认，没抄 niri 的 backdrop 玩法） |

### 3.3 完全没移植（umbriel 没有对应能力）

- **`Mod+O` 的 `toggle-window-rule-opacity`**：umbriel 的 `opacity` 只是窗口规则，
  没有运行期切换动作。（`rules.toml` 里仍保留了 niri 的 0.9 / 未聚焦 0.8 两条规则。）
- **`Mod+Escape` 的 `toggle-keyboard-shortcuts-inhibit`**：umbriel 无此动作。
  这个键位改成了 umbriel 内置的 `session-quit`（测试会话总得有个退出键）。
- **截图动作**：umbriel **没有**内置 `screenshot-window` / `screenshot-screen` / `screenshot`，
  也**没有** `screenshot-path`。区域/标注截图本来就走 noctalia IPC，原样保留；
  niri 的 F12 那组改成 noctalia 的 `screenshot-fullscreen`：
  - `Mod+F12` → `screenshot-fullscreen pick`（交互选择）
  - `Mod+Shift+F12` → 聚焦显示器
  - `Mod+Shift+Ctrl+S` → `all`（所有输出）

  窗口级截图没有直接等价物；portal 那条路（浏览器共享 / OBS）由 `xdg-desktop-portal-umbriel` 负责。
- **`min-width 876`**（OBS 那条）：umbriel 的规则没有 min-size 键。
- **微信那条浮动规则**：niri 写的是"标题是 图片和视频 / 朋友圈 / 微信，且 `exclude app-id=wechat`"，
  umbriel 没有否定匹配，硬翻会把官方 wechat 主窗口也浮起来，所以**整条没移植**。
- **多显示器方向的"到边不环绕"**：niri 的 `focus-monitor-left/right` 语义由
  `output-focus-left/right` 承接（单屏时按下去报 `no output to the left`，等于没反应）；
  umbriel 另有一对可环绕的 `output-focus-next/previous`，没绑（要的话自己加键）。
- **`swayidle.sh` / `change-idle-time.sh` / `ClipManager.sh`**：这三个脚本在 niri 侧也没被
  任何按键或启动项引用（idle/锁屏/剪贴板都交给 noctalia 了），所以没有移植。
  移植的只有 `lock.sh` / `float.sh` / `switch.sh` / `satty-last.sh`。

### 3.4 会话 / 系统层面

- **默认会话不变**：`programs.umbriel.enable` 只做两件事——装包，以及用
  `services.displayManager.sessionPackages` 注册一个 `Name=Umbriel` 的 wayland 会话
  （greetd / noctalia-greeter 靠 `sessionData.desktops` 找它）。`greetd.nix` 里的
  `session.default = "niri"` 没动。
- **portal 是增量的**：umbriel 模块会往 `xdg.portal` 加 `extraPortals += portal` 和
  `config.umbriel.default = [ "umbriel" "gtk" ]`。niri 模块写的是 `config.niri.*`，
  按 `XDG_CURRENT_DESKTOP` 选段，所以 niri 会话的 portal 行为不变。
  不想多编译一个 portal 就把 `modules/nixos/umbriel.nix` 里的
  `programs.umbriel.portalPackage = null` 取消注释。
- **首次 switch 慢**：umbriel 没有 cachix 缓存（`base.nix` 里只加了 noctalia 的），
  第一次要本地编译 umbriel + xdg-desktop-portal-umbriel。
- **`umbriel` 输入用 `git+https` 而不是 `github:`**：`github:` 走 `api.github.com` 解析分支，
  未认证限额 60 次/小时，共享出口 IP 一满 `nix flake lock` 就 403（这次就撞上了）；
  `git+https` 走 git 协议不碰那个接口。上游 flake 自带的 portal 输入同理覆盖成本地写法。
- **不做 `inputs.nixpkgs.follows`**：上游 pin 的是 nixos-unstable，umbriel 要 wlroots 0.20.1+/C++23，
  跟着本仓库的 `nixos-26.05` 混编风险更大；而且它本来就没有缓存可命中。
- `flake.lock` 只新增了 `umbriel`、`umbriel/nixpkgs`、`umbriel/xdg-desktop-portal-umbriel`
  三个节点，已有输入（nixpkgs/home-manager/noctalia/zen-browser）**没动**。

## 4. 脚本移植说明

| 脚本 | 改了什么 |
| --- | --- |
| `satty-last.sh` | 没改逻辑，只改了注释里的会话名。它只读 `~/Pictures/Screenshots`，不碰合成器 IPC |
| `lock.sh` | `niri msg action do-screen-transition` 去掉（umbriel 没有过渡动画动作）、`power-off-monitors` → `umbriel msg dpms-off`，锁屏仍是 `noctalia msg session lock` |
| `float.sh` | `niri msg --json windows` → `umbriel windows --json`；字段 `is_focused`/`is_floating` → `focused`/`floating`；`niri msg action` → `umbriel msg` |
| `switch.sh` | 同上换 IPC；窗口 id 两边都是 ext-foreign-toplevel 的字符串标识 |

注意：umbriel 的 `umbriel windows --json` **只报已映射（mapped）的窗口**，
而 `switch.sh` 原本在 niri 下也只能看到 niri 报的窗口；托盘里藏起来的窗口两边都找不到。

## 5. 为什么 umbriel 的配置目录是 out-of-store 软链

`modules/home/umbriel.nix` 把 `~/.config/umbriel` 整目录软链到 `dotfiles/umbriel`，
而不是像 niri 那样用 store 逐文件软链。原因是 **noctalia 要往里写文件**：
`share/noctalia/assets/templates/umbriel/apply.sh` 会往 `config.toml` 的 `[include]` 里插
`"noctalia.toml"`，模板本身还会渲染出 `~/.config/umbriel/noctalia.toml`（调色板）。
只读的 store 软链会让那次写入失败（和 rime / foot 是同一类坑，见 `AGENTS.md` 第 6、8 节）。

另外 `config.toml` 的 `[include] files` 里**已经**列了 `"noctalia.toml"`：umbriel 对必需
include 缺失的处理是"启动即失败"，所以仓库里放了一份只有注释的合法 TOML 占位
（`dotfiles/umbriel/noctalia.toml`），noctalia 还没接管配色之前也能正常起会话。

### 配色还差一步（本次刻意没动）

`dotfiles/noctalia/config.toml` 里现在是：

```toml
[theme.templates]
builtin_ids = [ "btop", "cava", "foot", "gtk3", "gtk4", "ghostty", "niri", "qt", "starship" ]
```

**没有 `"umbriel"`** —— 按"其他不要动"的要求，这次没有改它。所以 umbriel 现在用的是
它自己的内置默认配色（也是深色，能用）。想让 noctalia 接管 umbriel 的配色：

1. 往上面的列表里加 `"umbriel"`；
2. `sudo nixos-rebuild switch ...`（noctalia 的 config 是 store 链接，得 rebuild）；
3. 应用一次主题（或 `noctalia msg templates-apply`）。

之后 noctalia 会渲染 `dotfiles/umbriel/noctalia.toml`，并且**可能把 `config.toml` 里
`files = [ ... ]` 那一行改写成它自己的排版**（内容等价：`"noctalia.toml"` 保证排在最后）。
这是模板脚本的预期行为，别去"修"它。

## 6. 其他

- 上游是活跃开发中的项目，**键名会变**。改完先 `umbriel validate -c ~/.config/umbriel/config.toml`，
  它在不跑合成器的情况下就能报错（错误面板也会在会话里显示，最多列 6 条）。
- `dotfiles/umbriel/machine-custom.toml` 是可选的（`[include.optional]`），缺文件**不报错**；
  niri 那边缺 `machine-custom.kdl` 会报错、按 `AGENTS.md` 第 8 节第 7 条忽略即可，两件事无关。
- `AGENTS.md` 第 5 节的"dotfiles 挂载方式"表还没有 umbriel 这一行（新增的 out-of-store 目录），
  本次没改 AGENTS.md，需要的话自己补：`umbriel`（整目录 out-of-store，改完不用 rebuild）。
- 回滚 = 删掉 `hosts/nixos-adol/default.nix` 与 `home/keith/default.nix` 里那两行 import
  （以及 `flake.nix` 的 umbriel 输入和 `dotfiles/umbriel/`）。niri 侧没有被改过任何一行。
