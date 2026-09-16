# AGENTS.md — nix-config 仓库工作指南

给 AI 编码代理（以及未来的自己）的仓库说明。**动这个仓库前先读它。**
`dotfiles/nvim/` 下另有一份专门的 `AGENTS.md`，改 nvim 配置时以那份为准。
修改配置就行，说明改动范围和接下来动作，不用验证

## 1. 仓库概览

| 项 | 值 |
| --- | --- |
| 类型 | 单机 NixOS + home-manager flake 配置 |
| 主机 | `nixos-adol`（`networking.hostName = "adol"`） |
| 用户 | `keith`（属组 `wheel`、`networkmanager`） |
| 系统 / stateVersion | `26.05` |
| 输入 | `nixpkgs` → `nixos-26.05`；`home-manager` → `release-26.05`（follows nixpkgs）；`noctalia` → `github:noctalia-dev/noctalia/cachix`（**不** follows，见第 8 节第 14 条）；`zen-browser` → `github:0xc000022070/zen-browser-flake`（两个 follows 都加，见第 8 节第 12 条）；`umbriel` → `git+https://github.com/noctalia-dev/umbriel`（**不** follows，见第 8 节第 15 条） |
| 时区 / 桌面 | `Asia/Shanghai` / niri + Noctalia(v5) + noctalia-greeter 登录器；会话选择器里另有 Umbriel（可选测试会话，默认会话仍是 niri，见第 8 节第 15 条） |
| 上游远端 | `git@github.com:Keith994/nixos-configuration.git`（本地目录名是 `~/nix-config`） |

只有**一个** host、**一个**用户。`flake.nix` 里硬编码 `system = "x86_64-linux"`、`username = "keith"`，
通过 `specialArgs` / `home-manager.extraSpecialArgs` 传给所有模块。

## 2. 目录结构

```
flake.nix                     # 唯一入口：nixosConfigurations.nixos-adol
flake.lock                    # 输入锁定，只有升级依赖时才该变化
hosts/nixos-adol/
  default.nix                 # 主机装配：imports 列表 + 引导器 / hostName / 用户
  hardware-configuration.nix  # 机器相关，一般不要手改
home/keith/default.nix        # home-manager 入口：imports 列表 + home.* 基础设置
modules/nixos/*.nix           # 系统级模块
modules/home/*.nix            # 用户级模块（home-manager）
modules/home/ai/*.nix         # AI 工具（dsh）
dotfiles/                     # 真实配置文件，按程序分目录
  nvim/  niri/  umbriel/  ghostty/  foot/  tmux/  yazi/  rime/  noctalia/  starship/  fontconfig/  mpv/
```

## 3. 常用命令

```bash
# 应用配置（= shell alias nr）
sudo nixos-rebuild switch --flake ~/nix-config#nixos-adol

# 只构建不切换（= nb）
sudo nixos-rebuild build --flake ~/nix-config#nixos-adol

# 全量检查（= nc）
nix flake check ~/nix-config

# 只做求值的快速回归：能抓出绝大多数类型 / 选项 / import 错误，比 rebuild 快得多
nix eval .#nixosConfigurations.nixos-adol.config.system.build.toplevel.drvPath

# 格式化（仓库使用 nixfmt-rfc-style 风格：2 空格缩进）
nixfmt <file.nix>
```

沙箱提示：`nix` 需要写 `~/.cache/nix` 和 `/nix/store`。被文件沙箱挡住时可加
`XDG_CACHE_HOME=/tmp/nixcache`；若 `/nix/store` 也不可写导致 eval 失败，那是环境限制，不是配置写错了。

## 4. 模块清单

### 系统层 `modules/nixos/`

| 文件 | 作用 |
| --- | --- |
| `base.nix` | networkmanager、时区、flakes 实验特性、zram、git/neovim、`allowUnfreePredicate`(google-chrome / obsidian)；Cachix substituter（noctalia） |
| `ssh.nix` | openssh：密码登录开，root 登录关 |
| `shell.nix` | 系统层启用 zsh，并把普通用户 shell 设为 zsh（不影响 root） |
| `fonts.nix` | 字体包都在这：maple-mono.NF-CN（拉丁/终端）、lxgw-wenkai（中文）、nerd-fonts.jetbrains-mono、nerd-fonts.symbols-only。fonts.conf 里点名的 family 必须能在这些包里找到（见第 8 节第 11 条） |
| `icons.nix` | 图标 / 光标主题包：papirus、adwaita（托盘与 symbolic 图标）、`bibata-cursors`（光标本体，装在 system 级是为了 greeter 用户也解析得到，见第 8 节第 16 条）、glib/gsettings-desktop-schemas |
| `compat.nix` | `programs.nix-ld`，用于跑非 Nix 的动态链接二进制 |
| `niri.nix` | `programs.niri` + xwayland-satellite + ozone Wayland 环境变量 |
| `umbriel.nix` | `inputs.umbriel` 的 `programs.umbriel`：装包 + 注册一个 `Name=Umbriel` 的 wayland 会话 + portal（纯增量，默认会话仍是 niri，见第 8 节第 15 条） |
| `noctalia.nix` | noctalia shell 需要的系统服务：蓝牙、upower、power-profiles-daemon（wifi 在 base.nix） |
| `greetd.nix` | noctalia-greeter：greetd + `greeter.toml`（tmpfiles）+ AccountsService/polkit（见第 8 节第 8 条） |
| `clash-verge.nix` | `programs.clash-verge`（serviceMode + `clash-verge` 组）；GUI 由 `dotfiles/niri/startup.kdl` 拉起，不用模块的 autoStart |
| `fcitx5.nix` | fcitx5 + `waylandFrontend`，rime 引擎用 rime-ice |
| `vmware.nix` | VMware guest 支持 —— **当前没有被任何 host import**，需要时自行加进 `hosts/nixos-adol/default.nix` |

### 用户层 `modules/home/`

| 文件 | 作用 |
| --- | --- |
| `shell.nix` | zsh：fzf-tab、自动建议、语法高亮、history、别名 `nr/nb/nc/nixcfg`；末尾 `source ~/.ai-api.zsh`（仓库外密钥） |
| `cli.nix` | fzf、zoxide、eza、bat、direnv(+nix-direnv)，以及 ripgrep/fd/jq/htop/btop 等 |
| `git.nix` | `programs.git`：main 分支、fetch.prune、editor=nvim、ignore 规则；身份信息从 `~/.config/git/local.conf` include |
| `starship.nix` | starship 提示符；`~/.config/starship.toml` 是指向 `dotfiles/starship/starship.toml` 的 out-of-store 软链（**必须可写**：noctalia 每次换壁纸都往里注入调色板块，所以那个文件被忽略、手写原始版跟踪在 `starship.toml.orig`）；`configPath` 必须与文件落点一致（见第 8 节第 2 条） |
| `nvim.nix` | EDITOR/VISUAL=nvim、`vi`/`vim` 别名、编译依赖；`~/.config/nvim` 软链到仓库 |
| `ghostty.nix` | ghostty（nixpkgs 稳定版）+ zsh 集成；整个 `dotfiles/ghostty` **目录** out-of-store 软链（config 里的相对路径 `shader/`、`themes/` 和 noctalia 写的 `themes/noctalia` 都得落在仓库里，见第 5、8 节；nightly 试过，见第 8 节第 6 条） |
| `foot.nix` | 装 `foot` / `footclient`，整个 `dotfiles/foot` 目录 out-of-store 软链到 `~/.config/foot`；server 由 niri 启动项拉起（见第 8 节第 13 条） |
| `tmux.nix` | tmux，配置用 `builtins.readFile ../../dotfiles/tmux/tmux.conf` |
| `mpv.nix` | `pkgs.mpv.override`（挂 `mpvScripts.mpris`，让 noctalia 的媒体组件/媒体键能看到它）+ `dotfiles/mpv/{mpv.conf,input.conf}` 两个**单文件** out-of-store 软链（不整目录链：mpv 往 `~/.config/mpv/watch_later/` 写进度）；键位是 vim 风格 |
| `imv.nix` | `programs.imv`：Wayland 原生键盘图片查看器，深色底 + 浮层 + vim 的 `n`/`N` 翻图。**没**配默认打开方式：`~/.config/mimeapps.list` 是仓库外的手工文件（`image/png` 现在指向 Chrome），要改直接 `xdg-mime default imv.desktop image/png` |
| `satty.nix` | `programs.satty`（截图标注，只打开已有图片）+ `wl-clipboard`（satty 的 `copy-command` 要 `wl-copy`，顺便给终端用）；`Mod+Shift+A` 走 `dotfiles/niri/scripts/satty-last.sh` 标注最新一张截图（见第 8 节第 5 条） |
| `yazi.nix` | yazi + 预览依赖；整个 `dotfiles/yazi` 目录 out-of-store 软链（`ya pack` 装的东西会直接落进仓库，见第 5 节） |
| `niri.nix` | 整个 `dotfiles/niri` 目录 out-of-store 软链（noctalia 的 niri 模板要往这个目录写 `noctalia.kdl` 和 include 行，见第 5 节） |
| `umbriel.nix` | `~/.config/umbriel` → `dotfiles/umbriel` 整目录 out-of-store 软链（noctalia 会写 `noctalia.toml`）；刻意不 import 上游 `homeModules.default`（见第 8 节第 15 条） |
| `noctalia.nix` | `inputs.noctalia` 的 `programs.noctalia` 模块 + `dotfiles/noctalia/config.toml`（构建期 validate，见第 8 节第 14 条） |
| `rime.nix` | 见第 6 节「Rime 特例」 |
| `devtools.nix` | go / rustc / cargo / nodejs / yarn / lazygit / trash-cli / tree-sitter 等 |
| `chrome.nix` | `programs.chromium` + `pkgs.google-chrome`，强制 Wayland 与 fcitx5 IME |
| `zen.nix` | `inputs.zen-browser` 的 `programs.zen-browser` 模块（beta 通道，命令行 `zen-beta`）；nixpkgs 里没有这个包（见第 8 节第 12 条） |
| `apps.nix` | 没有 `programs.*` 模块、也不需要额外包装参数的 GUI 应用（obsidian、localsend、telegram-desktop）。unfree 的要同步 `base.nix` 的白名单 |
| `fontconfig.nix` | 把 `dotfiles/fontconfig/fonts.conf` 软链到 `~/.config/fontconfig/fonts.conf`（见第 8 节第 11 条） |
| `ai/deepseek-harness.nix` | 打包 `dsh` 命令（见第 7 节） |

## 5. dotfiles 的挂载方式（决定改完要不要 rebuild）

**动手前先查这张表**：

| 目标 | 方式 | 改完需要 rebuild？ |
| --- | --- | --- |
| `nvim`、`ghostty`、`foot`、`niri`、`yazi`、`umbriel`（整目录） | `mkOutOfStoreSymlink` 指向 `~/nix-config/dotfiles/...` | 否，保存即生效（foot 要重启 server 才读新配置，见第 8 节第 13 条；niri 会自己重载，umbriel 热重载） |
| `mpv/mpv.conf`、`mpv/input.conf`（单文件） | `mkOutOfStoreSymlink` 指向 `~/nix-config/dotfiles/mpv/*`：**不**整目录链，mpv 要往 `~/.config/mpv/watch_later/` 写播放进度 | 否，保存即生效 |
| `fontconfig/fonts.conf` | `xdg.configFile` 普通 source，落点 `~/.config/fontconfig/fonts.conf` | 是 |
| `noctalia/config.toml` | `programs.noctalia.settings` 指向仓库文件，构建期先 `noctalia config validate` 再软链 | 是 |
| `tmux` | 构建期 `builtins.readFile` 读进配置 | 是 |
| `starship.toml` | `mkOutOfStoreSymlink` 指向 `dotfiles/starship/starship.toml`：**必须可写**，noctalia 会写穿它；这个运行中的文件**不入库**（`.gitignore` 忽略），手写原始版跟踪在 `dotfiles/starship/starship.toml.orig` | 否，保存即生效（换壁纸会被 noctalia 注入调色板块，见下） |
| `rime` | 自定义 activation 拷贝（见第 6 节） | 是 |

`mkOutOfStoreSymlink` 把**绝对路径**写死成 `${config.home.homeDirectory}/nix-config/dotfiles/...`，
所以仓库必须留在 `~/nix-config`；换目录要同步改 `modules/home/` 下的 `nvim.nix`、`ghostty.nix`、
`foot.nix`、`mpv.nix`、`niri.nix`、`yazi.nix`、`umbriel.nix`、`starship.nix`。

目录级 out-of-store 软链（`~/.config/<app>` 整体指向仓库目录）除了"改完不用 rebuild"，还有一个硬需求：
**noctalia 的主题模板要往这些目录里写文件**（niri 的 `noctalia.kdl` 与 `config.kdl` 里的 include 行、
foot 的 `themes/noctalia` 与 `foot.ini` 的 include 行、umbriel 的 `noctalia.toml`、ghostty 的
`themes/noctalia`）。指向只读 store 的软链会让这些写入直接失败（和 rime 是同一类坑，见第 6 节），
所以这几个目录一律软链到工作区 —— 生成的文件因此也落在仓库里（哪些该进版本库、哪些刻意忽略，
见下一小节）。

代价有两条，动手时留意：

- 程序自己往这些目录里写的东西会**直接出现在仓库里**。最典型的是 `ya pack` 装的
  `dotfiles/yazi/{flavors,plugins}`、noctalia 渲染的主题文件，`git status` 里会多出未跟踪/已修改文件，
  要不要提交由你决定（`.gitignore` 只挡敏感文件，不挡这些）。
- `~/.config/<app>` 这个路径本身是**符号链接**，不要以为在仓库外新建同名文件能覆盖它；
  改动一律落在 `dotfiles/` 里。

### 刻意不进版本库的：noctalia 模板渲染产物

noctalia 的主题模板会往上面这些 out-of-store 目录里**写**文件，换一次主题全部重写，
提交进去只是噪音，所以 `.gitignore` 按**具体路径**忽略它们：

| 模板 | 仓库内被写掉的路径 | 顺带还改什么 |
| --- | --- | --- |
| `niri` | `dotfiles/niri/noctalia.kdl` | 往 `config.kdl` 追加 `include "noctalia.kdl"` |
| `foot` | `dotfiles/foot/themes/noctalia` | 往 `foot.ini` 插 `include=…` 行 |
| `ghostty` | `dotfiles/ghostty/themes/noctalia` | 往 `config` 追加/改写 `theme = noctalia`（config 是手写 + 会被改写，照旧跟踪） |
| `umbriel` | `dotfiles/umbriel/noctalia.toml` | 重写 `config.toml` 的 `[include] files` 行 |
| `yazi`（**社区**模板） | `dotfiles/yazi/theme.toml`、`dotfiles/yazi/flavors/noctalia.yazi/` | `apply.sh` 会整份覆盖 `theme.toml` |

- **不要**写 `**/noctalia` / `**/noctalia.*` 这种宽规则：它会连带命中手写的 `dotfiles/noctalia/` 目录，
  而 noctalia 会把那个目录下所有 `*.toml` 合并加载 —— 被忽略就等于"改了配置不生效 / 提交时漏文件"。
- 代价：这些文件正是各配置里 include 的目标，所以**全新 clone（或 `git clean -xdf`）之后必须先跑一次
  noctalia 主题**，否则 niri / foot 报 include 缺失、umbriel 直接起不来、yazi 掉回默认主题。
- 只影响运行时渲染、不影响 flake 求值：flake 源码本来就不含未跟踪/被忽略的文件，而运行时读的是
  out-of-store 软链指向的工作区。
- **`dotfiles/starship/starship.toml` 也属于"被 noctalia 注入"的那一类**，但它走的是另一套办法：
  starship 没有 include 机制，模板只能把 `palette = "noctalia"` + 末尾一段带 marker 的调色板块
  **内联**进这个文件，每次换壁纸都会改一遍。所以运行中那份 `.gitignore` 忽略、**手写原始版**
  跟踪成 `dotfiles/starship/starship.toml.orig`；要改提示符配置就改 `.orig`，还原 / 新机器：
  `cp dotfiles/starship/starship.toml.orig dotfiles/starship/starship.toml`
  （不 cp 的话 `~/.config/starship.toml` 是**悬空软链** → starship 静默回退内置默认配置，没有任何报错）。
- **例外：`dotfiles/ghostty/config` 照旧跟踪、不忽略** —— noctalia 只往它里面改/加一行
  `theme = noctalia`，而它承载着字体、键位、shader 一大堆手写设置，所以换主题后变脏就正常 review 提交。

## 6. Rime 特例（不要"顺手优化"掉）

`modules/home/rime.nix` 刻意没用 `home.file`，而是在 `home.activation` 里 `install` 一份可写副本并删掉
`build/default.yaml`。原因（文件注释里有更完整的版本）：

- librime 用 **mtime** 判断配置是否需要重新部署，而 Nix store 文件 mtime 恒为 0 → 软链方案改了配置也不生效；
- Rime 会回写 `default.custom.yaml`，指向只读 store 的软链会报 `failed to save config to stream`；
- 现有写法是「内容真变了才拷贝 + 删 `build/default.yaml` 强制重新合并」，只重合并不重建词库，代价很小。

## 7. dsh（DeepSeek Harness）

`modules/home/ai/deepseek-harness.nix` 用 `writeShellApplication` 包装 `dsh`：

- 版本 **pin** 在 `@deepseek-ai/dsh@0.1.5-rc.1`（`npx --package=...`），升级 = 改这一行 + rebuild；
- runner 用 `node --expose-internals` 启动由 `$(command -v dsh)` 解析出的真实入口；
- 设置 `DSH_HOME = ${xdg.dataHome}/deepseek-harness`；
- `runtimeInputs` 里除 `nodejs_24` / `coreutils` 外还有 `pnpmOnly`、`gcc`、`python3`、`gnumake`：
  前者给 `dsh plugin --profile <name> <pnpm 参数>`（转发给 pnpm）用，后三者给 node-gyp 现场编译
  原生模块用（例如 `dsh-better-sidebar` 依赖的 `node-pty`）。它们只在 wrapper 的 PATH 上，不进全局环境；
- `pnpmOnly` 是用 `symlinkJoin` 去掉 `pkgs.pnpm` 自带可执行文件（`node`/`npx`/`corepack`）、只留
  `bin/pnpm`、`bin/pnpx` 的包装，避免它按 PATH 顺序遮蔽 `nodejs_24` —— **不要**图省事直接写 `pnpm`。

**插件装在仓库外**：`dsh plugin` 装出来的插件落在 `$DSH_HOME/profiles/<profile>/`（`package.json` 的
`dsh.profile.bundles` + `node_modules`），不属于这份 flake，`git status` 里看不到。声明了
`dsh.bundle.patch` 的包会被自动追加成一层，没声明的只是普通依赖、要在 profile 的 `cordis.patch.yml`
里自己 insert 一行。`patchReload: live` 只热加载用户层 patch 文件，**改了 bundles 必须重启对应 profile
的进程**（如 `dsh web`）才生效。

## 8. 已知问题 / 陷阱

1. 仓库外的本地/密钥文件绝不入库：`~/.ai-api.zsh`（`shell.nix` source）、`~/.config/git/local.conf`（身份）、
   `dotfiles/nvim/lua/plugins/dbs_url/`（数据库明文）。`.gitignore` 已覆盖这些，新增同类文件时同步补规则。
2. `modules/home/starship.nix` 的 `configPath` 必须和 `xdg.configFile."starship.toml"` 的落点**完全一致**：
   指到不存在的路径时 starship 会**静默**回退到内置默认配置（自定义 toml 被整个忽略，看着就像"配置没生效"）。
   现在两边都是 `~/.config/starship.toml`，而它是指向 `dotfiles/starship/starship.toml` 的 out-of-store
   软链（noctalia 的 starship 模板要写穿它），挪文件或改链要一起改。
   **注意那个目标文件不在版本库里**（它每次换壁纸都被 noctalia 注入，见第 5 节）：新机器 / 还原之后
   必须先 `cp dotfiles/starship/starship.toml.orig dotfiles/starship/starship.toml` —— 目标不存在时
   软链是悬空的，starship 一样静默回退默认配置，**全程没有任何报错**。
3. 只有单 host / 单 user：新增主机要改 `flake.nix` 的 outputs，并考虑把 `username`、`system` 参数化。
4. 桌面启动项（`dotfiles/niri/startup.kdl`）里有 `ydotoold`、`polkit-gnome` 等，
   它们并不都由这份 flake 安装 —— 排查"命令找不到"时先确认是 Nix 装的还是手工装的
   （`clash-verge` 由 `modules/nixos/clash-verge.nix` 装，走 serviceMode + `clash-verge` 组；
   `foot --server` 里的 foot 由 `modules/home/foot.nix` 装，见第 13 条）。
   通知（`org.freedesktop.Notifications`）和剪贴板历史现在由 noctalia 接管，不要再装 mako/dunst/cliphist。
5. 截图**不依赖** grim / slurp（这两个包这份 flake 没装，`dotfiles/niri/keys.kdl` 里曾经
    `spawn-sh` 一个仓库里根本不存在的 `satty-screenshot.sh`，按下去只是静默失败）。截图入口是
    niri 26.04 内置动作（`screenshot` / `screenshot-screen` / `screenshot-window`，落盘路径由
    `config.kdl` 的 `screenshot-path` 决定，现在是 `~/Pictures/Screenshots/` 下带 `%Y-%m-%d %H-%M-%S`
    时间戳的文件）+ noctalia v5 的 `screenshot-region` / `screenshot-annotate` IPC。
    要改截图按键先看 `noctalia msg --help` 里有没有现成子命令，别再引入外部截图工具链。
   satty 现在**装了**（`modules/home/satty.nix`，连带 `wl-clipboard`），但它只做「打开已有图片来画」：
   `Mod+Shift+A` → `dotfiles/niri/scripts/satty-last.sh` 打开截图目录里最新的一张。
   也就是说 satty 不参与截图、只是标注器，`noctalia msg annotate <path>` 是它的同类替代。
6. ghostty 保持 nixpkgs 的稳定版（`programs.ghostty` 默认的 `pkgs.ghostty`）。
   **nightly 试过并回退了**：2026-09 曾接官方 flake（`github:ghostty-org/ghostty/tip`，
   `programs.ghostty.package = inputs.ghostty.packages.${...}.default`）并配上上游 CI 的
   `ghostty.cachix.org`（那个 cache 确实可用，命中的 nar.zst 约 25 MiB），但实测启动后**黑屏**，
   所以整体回滚：`flake.nix` 的 `ghostty` 输入、`flake.lock` 的对应节点、`base.nix` 里的
   ghostty substituter / public key 都已删除。要再试的话记得这几点：
   - 上游 flake **不要**加 `inputs.nixpkgs.follows`（它自带 pin 的 zig overlay 和 nixpkgs）；
   - 它的包不在 cache.nixos.org 上，得加 `https://ghostty.cachix.org` 才不用本地 zig build；
   - nixpkgs 的 `pkgs.ghostty-bin` 只支持 darwin（macOS `.dmg` 重打包），Linux 上没用；
   - `dotfiles/ghostty` 是**整目录** out-of-store 软链（见第 5 节），改配置本来就不用 rebuild —— 但别改回
     只链 `config` 单文件：config 里的相对路径是按 `~/.config/ghostty/` 解析的，单文件链时那里没有
     `shader/`，日志里会固定出现
     `warning(generic_renderer): error loading custom shaders err=error.FileNotFound`
     （`custom-shader = shader/cursor_warp.glsl` 实测就这样静默失效过），`themes/` 读到的也会是
     仓库外手工拷的那份。
7. 忽略 niri 的 `machine-custom.kdl` 报错：`config.kdl` 无条件 include 它，而这个文件不进版本库
   （`.git/info/exclude` 里挡着）。umbriel 的对应物 `machine-custom.toml` 是 `[include.optional]`，
   缺文件静默忽略、不报错 —— 两件事无关，别混。
8. `modules/nixos/greetd.nix` 没有用上游的 `services.displayManager.noctalia-greeter` 模块 —— 锁定的 nixpkgs 26.05
   里只有包（`pkgs.noctalia` / `pkgs.noctalia-greeter`）没有模块。两个硬约束：greeter 只读
   `/var/lib/noctalia-greeter/greeter.toml`（用 tmpfiles `L+` 软链进 store），且它靠 `XDG_DATA_DIRS`
   找 `*.desktop` 会话、会话包装脚本还要 `dbus-run-session`（greetd 服务自身环境里都没有），
   所以 greetd 的 command 指向一层包装脚本。AccountsService（用户列表/头像）与 polkit 也是它要的。
9. `dotfiles/nvim/` 有独立 `AGENTS.md`；nvim 目录是 out-of-store 软链，改 Lua **不需要** rebuild 但会被立刻读取。
10. imv **没**配默认打开方式：`~/.config/mimeapps.list` 是仓库外的手工文件（`image/png` 现在指向 Chrome），
    要改直接 `xdg-mime default imv.desktop image/png`。
11. 字体（`modules/nixos/fonts.nix` + `dotfiles/fontconfig/fonts.conf`）：
    - `fonts.conf` 里点名的 family **必须**在这份 flake 装的字体包里真的存在（改名字前先确认 `pkgs` 里有）。
      历史上这里写过 `Liga SFMono Nerd Font`（nixpkgs 没有，SF Mono 是 Apple 授权字体），family 解析不到时
      serif / sans-serif / monospace 会整体 fallback 到 DejaVu，等于整段配置白写。
    - 规则一律用 `qual="first"`（只看 pattern 里**第一个** family），中文组必须排在拉丁组**前面**，理由写在
      `fonts.conf` 顶部注释里：系统自带的 `49-sansserif.conf` 会给任何不含 generic 的请求末尾追加一个
      `binding="weak"` 的 `sans-serif`，用默认的 `qual="any"` 会把显式 family 请求（`Maple Mono NF CN` /
      `DejaVu Sans` / …）也判成中文/sans-serif，实测 `fc-match` 全部返回霞鹜文楷。
    - 请求带不带 `lang=zh` 取决于**进程的 locale**：niri 会话里由 systemd/D-Bus 拉起的进程是 `en_US`，
      umbriel 会话（`[environment] LANG=zh_CN.UTF-8` 会发布到 user manager 和 D-Bus）里几乎全是 `zh` ——
      同一份配置在两个会话里字体不一样是预期行为，不是配置没生效。
12. zen-browser 在 nixpkgs 26.05 里**不存在**，用 `inputs.zen-browser` 那个社区 flake：两个 follows 都要加
    （nixpkgs follows 是为了 autoPatchelfHook 链到版本匹配的系统库，home-manager follows 是为了它的
    mkFirefoxModule 语义跟本地 HM 一致）。装出来的命令是 `zen-beta`，不带包装的 `zen` 不要直接用。
13. foot 是整目录 out-of-store 软链（原因见第 5 节），因此**不能**再设 `programs.foot.settings`
    （HM 会想在 `foot/foot.ini` 落文件，和整目录软链冲突）。foot 只在启动时读一次配置，
    改完必须**重启 foot server** 才生效（`pkill foot` 后重登会话，或手动补一条 `foot --server`）；
    `SIGUSR1`/`SIGUSR2` 只切 `[colors-dark]`/`[colors-light]`，不是重载配置。
14. noctalia 走 `inputs.noctalia`（`github:noctalia-dev/noctalia/cachix`）拿 5.1.x 包 + `programs.noctalia` 模块：
    - **不要**给它加 `inputs.nixpkgs.follows`，也不要覆盖它的 nixpkgs —— 官方 Cachix 缓存按它自己的 nixpkgs
      构建，改了输入就等于放弃缓存（会本地编译 C++）。substituter 配在 `modules/nixos/base.nix` 的 `nix.settings`；
    - lock 在 `cachix` 分支（永远指向 CI 已缓存的提交），`main` 可能还没缓存；
    - `programs.noctalia.settings` 直接指向 `dotfiles/noctalia/config.toml`，`checkConfig = true` 会在**构建期**
      跑 `noctalia config validate`，键名写错直接 build 失败（这是好事）；
    - 运行时配置分两层：`~/.config/noctalia/*.toml`（仓库软链，只读）优先级低，
      `~/.local/state/noctalia/settings.toml`（GUI/IPC 写的）优先级高 —— 改了仓库配置不生效时先看/删后者；
    - **模板选择也在 state 层**：真正生效的是 `settings.toml` 的 `[theme.templates]`（现在是
      `builtin_ids = [ … "umbriel" ]` + `community_ids = [ "telegram", "yazi" ]`），仓库那份
      `dotfiles/noctalia/config.toml` 里的列表只是低优先级默认值。判断"某个模板会不会跑、会写哪些文件"，
      要去看 state 文件 + `~/.local/state/noctalia/community-templates/`；
    - 模板的渲染产物**不入库**（`.gitignore` 按路径忽略，清单见第 5 节），starship 的运行中配置
      （原始版另存 `dotfiles/starship/starship.toml.orig`）也在其中；唯一例外是 `dotfiles/ghostty/config`：
      它照旧跟踪，因为 noctalia 只往里面改/加一行 `theme = noctalia`，其余全是手写内容（见第 5 节）；
    - 系统 nixpkgs 26.05 里虽然有 `pkgs.noctalia`，但版本比上游 flake 旧、也没有模块，不要混用。
15. umbriel 是 noctalia 官方的 wlroots 合成器，**只是会话选择器里的可选测试会话**（greetd 的
    `session.default` 仍是 `niri`）。要点：
    - 上游 pin 的是 nixos-unstable，**不加** `inputs.nixpkgs.follows`（它要 wlroots 0.20.1+ / C++23），
      也没有 cachix —— 首次 switch 要本地编译 umbriel + `xdg-desktop-portal-umbriel`，很慢；
    - 输入 URL 用 `git+https://` 而不是 `github:`（后者走 `api.github.com`，未认证 60 次/小时的限额一满
      `nix flake lock` 就 403）；
    - 配置是 `dotfiles/umbriel/*.toml`（从 niri 的 KDL 逐条翻译，差异清单在 `dotfiles/umbriel/README.md`），
      键名随上游版本变，改完先 `umbriel validate -c ~/.config/umbriel/config.toml`；
    - `modules/home/umbriel.nix` 刻意不 import 上游 `homeModules.default`：`programs.umbriel.settings` 只能写
      单文件、挡不住 `[include]` 引用的同目录文件，而且它会把 umbriel 再装进 `home.packages`。
16. 光标主题统一成 `Bibata-Modern-Ice`、尺寸 20，**四处字面量必须一致**：
    `modules/nixos/icons.nix`（装包，system 级是为了 greeter 用户也解析得到）、`modules/nixos/greetd.nix`
    （`greeter.toml` 的 `cursor.theme` / `cursor.size`）、`dotfiles/niri/environment.kdl` 的
    `XCURSOR_THEME` / `XCURSOR_SIZE` + `config.kdl` 的 `cursor { xcursor-size 20 }`、
    `dotfiles/umbriel/config.toml` 的 `[input.cursor].theme`/`size` 与 `[environment]` 里的同名变量。
    不设 `XCURSOR_THEME` 时 xcursor 会去找名为 `default` 的主题（本机没有），于是合成器自己画的
    边缘拖拽/移动光标、以及 Qt / XWayland / Electron 各自回退到内置箭头，看着就是"光标混用"。
    `[environment]` / niri 的 `environment {}` **只在会话启动时生效**，改完要重开会话。

## 9. 改动流程（checklist）

1. **定位层**：系统级 → `modules/nixos/`；用户级 → `modules/home/`；纯配置 → `dotfiles/`。
2. **加包**：优先用 `programs.*` 模块；没有再退到 `home.packages` / `environment.systemPackages`（用 `with pkgs;`）。
3. **新模块**：写文件后必须在 `home/keith/default.nix` 或 `hosts/nixos-adol/default.nix` 的 `imports` 里注册 —— Nix 不会自动发现。
4. **风格**：2 空格缩进、nixfmt-rfc-style；函数头写成 `{ pkgs, ... }:`，空一行再写 `{`；注释用中文，解释「为什么」而不是「做了什么」。
5. **验证**：先 `nix eval ...toplevel.drvPath`；再按需 `nixos-rebuild build` / `switch`。走 store 软链或构建期读取的改动（`tmux`、`rime`、`noctalia`、`fontconfig`）**必须** rebuild 才生效；`nvim` / `ghostty` / `foot` / `mpv` / `niri` / `yazi` / `umbriel` / `starship` 是 out-of-store 软链，保存即生效（见第 5 节表）。
6. **提交**：仓库历史是简短自由格式、无 CI。一次提交只做一件事，别把 `flake.lock` 的大范围更新和功能改动混在一起。
