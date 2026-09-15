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
| 输入 | `nixpkgs` → `nixos-26.05`；`home-manager` → `release-26.05`（follows nixpkgs）；`noctalia` → `github:noctalia-dev/noctalia/cachix`（**不** follows，见第 8 节第 7 条）；`zen-browser` → `github:0xc000022070/zen-browser-flake`（两个 follows 都加，见第 8 节第 12 条） |
| 时区 / 桌面 | `Asia/Shanghai` / niri + Noctalia(v5) + noctalia-greeter 登录器 |
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
  nvim/  niri/  ghostty/  tmux/  yazi/  rime/  noctalia/  fontconfig/
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
| `base.nix` | networkmanager、时区、flakes 实验特性、zram、git/neovim、`allowUnfreePredicate`(google-chrome / obsidian) |
| `ssh.nix` | openssh：密码登录开，root 登录关 |
| `shell.nix` | 系统层启用 zsh，并把普通用户 shell 设为 zsh（不影响 root） |
| `fonts.nix` | 字体包都在这：maple-mono.NF-CN（拉丁/终端）、lxgw-wenkai（中文）、nerd-fonts.jetbrains-mono、nerd-fonts.symbols-only。fonts.conf 里点名的 family 必须能在这些包里找到（见第 8 节第 11 条） |
| `compat.nix` | `programs.nix-ld`，用于跑非 Nix 的动态链接二进制 |
| `niri.nix` | `programs.niri` + xwayland-satellite + ozone Wayland 环境变量 |
| `noctalia.nix` | noctalia shell 需要的系统服务：蓝牙、upower、power-profiles-daemon（wifi 在 base.nix） |
| `greetd.nix` | noctalia-greeter：greetd + `greeter.toml`（tmpfiles）+ AccountsService/polkit（见第 8 节第 8 条） |
| `fcitx5.nix` | fcitx5 + `waylandFrontend`，rime 引擎用 rime-ice |
| `vmware.nix` | VMware guest 支持 —— **当前没有被任何 host import**，需要时自行加进 `hosts/nixos-adol/default.nix` |

### 用户层 `modules/home/`

| 文件 | 作用 |
| --- | --- |
| `shell.nix` | zsh：fzf-tab、自动建议、语法高亮、history、别名 `nr/nb/nc/nixcfg`；末尾 `source ~/.ai-api.zsh`（仓库外密钥） |
| `cli.nix` | fzf、zoxide、eza、bat、direnv(+nix-direnv)，以及 ripgrep/fd/jq/htop/btop 等 |
| `git.nix` | `programs.git`：main 分支、fetch.prune、editor=nvim、ignore 规则；身份信息从 `~/.config/git/local.conf` include |
| `starship.nix` | starship 提示符 + `modules/home/starship.toml`；`configPath` 必须与文件落点一致（见第 8 节第 2 条） |
| `nvim.nix` | EDITOR/VISUAL=nvim、`vi`/`vim` 别名、编译依赖；`~/.config/nvim` 软链到仓库 |
| `ghostty.nix` | ghostty + zsh 集成；只把 `config` 软链到仓库 |
| `foot.nix` | 装 `foot` / `footclient`，整个 `dotfiles/foot` 目录 out-of-store 软链到 `~/.config/foot`；server 由 niri 启动项拉起（见第 8 节第 13 条） |
| `tmux.nix` | tmux，配置用 `builtins.readFile ../../dotfiles/tmux/tmux.conf` |
| `yazi.nix` | yazi + 预览依赖；整个 `dotfiles/yazi` 递归链接 |
| `niri.nix` | 整个 `dotfiles/niri` 递归链接 |
| `noctalia.nix` | `inputs.noctalia` 的 `programs.noctalia` 模块 + `dotfiles/noctalia/config.toml`（构建期 validate，见第 8 节第 7 条） |
| `rime.nix` | 见第 6 节「Rime 特例」 |
| `devtools.nix` | go / rustc / cargo / nodejs / yarn / lazygit / trash-cli / tree-sitter 等 |
| `chrome.nix` | `programs.chromium` + `pkgs.google-chrome`，强制 Wayland 与 fcitx5 IME |
| `zen.nix` | `inputs.zen-browser` 的 `programs.zen-browser` 模块（beta 通道，命令行 `zen-beta`）；nixpkgs 里没有这个包（见第 8 节第 12 条） |
| `apps.nix` | 没有 `programs.*` 模块、也不需要额外包装参数的 GUI 应用（当前：obsidian）。unfree 的要同步 `base.nix` 的白名单 |
| `fontconfig.nix` | 把 `dotfiles/fontconfig/fonts.conf` 软链到 `~/.config/fontconfig/fonts.conf`（见第 8 节第 11 条） |
| `ai/deepseek-harness.nix` | 打包 `dsh` 命令（见第 7 节） |

## 5. dotfiles 的挂载方式（决定改完要不要 rebuild）

**动手前先查这张表**：

| 目标 | 方式 | 改完需要 rebuild？ |
| --- | --- | --- |
| `nvim`、`ghostty/config`、`foot`（整目录） | `mkOutOfStoreSymlink` 指向 `~/nix-config/dotfiles/...` | 否，保存即生效（foot 要重启 server 才读新配置，见第 8 节第 13 条） |
| `niri`、`yazi` | `xdg.configFile` 普通 source（store 逐文件软链） | 是 |
| `fontconfig/fonts.conf` | `xdg.configFile` 普通 source，落点 `~/.config/fontconfig/fonts.conf` | 是 |
| `noctalia/config.toml` | `programs.noctalia.settings` 指向仓库文件，构建期先 `noctalia config validate` 再软链 | 是 |
| `tmux` | 构建期 `builtins.readFile` 读进配置 | 是 |
| `starship.toml` | 仓库内文件链接 | 是 |
| `rime` | 自定义 activation 拷贝（见第 6 节） | 是 |

`mkOutOfStoreSymlink` 把**绝对路径**写死成 `${config.home.homeDirectory}/nix-config/dotfiles/...`，
所以仓库必须留在 `~/nix-config`；换目录要同步改 `modules/home/nvim.nix` 与 `ghostty.nix`。

niri / yazi 用 `recursive = true`，部署结果是「每个文件一条指向 store 的只读软链」，目录本身仍是可写的真实目录，
因此 yazi 的 `flavors/`、`plugins/` 才能共存。
**不要**直接编辑 `~/.config/<app>` 下的软链目标，改动要落在 `dotfiles/` 里。

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
2. `dotfiles/nvim/` 有独立 `AGENTS.md`；nvim 目录是 out-of-store 软链，改 Lua **不需要** rebuild 但会被立刻读取。
3. 只有单 host / 单 user：新增主机要改 `flake.nix` 的 outputs，并考虑把 `username`、`system` 参数化。
4. 桌面启动项（`dotfiles/niri/startup.kdl`）里有 `ydotoold`、`polkit-gnome` 等，
   它们并不都由这份 flake 安装 —— 排查"命令找不到"时先确认是 Nix 装的还是手工装的
   （`clash-verge` 由 `modules/nixos/clash-verge.nix` 装；`foot --server` 里的 foot 由
   `modules/home/foot.nix` 装，见第 13 条）。
   通知（`org.freedesktop.Notifications`）和剪贴板历史现在由 noctalia 接管，不要再装 mako/dunst/cliphist。
5. 截图**不依赖** grim / slurp / satty（这三个包这份 flake 从没装过，`dotfiles/niri/keys.kdl` 里曾经
    `spawn-sh` 一个仓库里根本不存在的 `satty-screenshot.sh`，按下去只是静默失败）。现在走
    niri 26.04 内置动作（`screenshot` / `screenshot-screen` / `screenshot-window`，落盘路径由
    `config.kdl` 的 `screenshot-path` 决定，现在是 `~/Pictures/Screenshots/` 下带 `%Y-%m-%d %H-%M-%S`
    时间戳的文件）+ noctalia v5 的 `screenshot-region` / `screenshot-annotate` IPC。
    要改截图按键先看 `noctalia msg --help` 里有没有现成子命令，别再引入外部截图工具链。

## 9. 改动流程（checklist）

1. **定位层**：系统级 → `modules/nixos/`；用户级 → `modules/home/`；纯配置 → `dotfiles/`。
2. **加包**：优先用 `programs.*` 模块；没有再退到 `home.packages` / `environment.systemPackages`（用 `with pkgs;`）。
3. **新模块**：写文件后必须在 `home/keith/default.nix` 或 `hosts/nixos-adol/default.nix` 的 `imports` 里注册 —— Nix 不会自动发现。
4. **风格**：2 空格缩进、nixfmt-rfc-style；函数头写成 `{ pkgs, ... }:`，空一行再写 `{`；注释用中文，解释「为什么」而不是「做了什么」。
5. **验证**：先 `nix eval ...toplevel.drvPath`；再按需 `nixos-rebuild build` / `switch`。走 store 软链（niri/yazi/tmux/rime/starship）的改动**必须** rebuild 才生效。
6. **提交**：仓库历史是简短自由格式、无 CI。一次提交只做一件事，别把 `flake.lock` 的大范围更新和功能改动混在一起。
