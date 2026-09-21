{ config, pkgs, ... }:

{
  # 看图 / 标注 / 播放这一组：imv、satty、mpv。三个都各自带一点额外约束
  # （窗口形态在 niri 的 rules.kdl、dotfile 怎么挂），所以合并成文件、注释按工具分段。

  # imv：Wayland 原生的键盘图片查看器，定位就是给平铺窗口管理器用的，
  # 默认键位已经很 vim（q 退出、x 关掉当前图、hjkl 平移、gg/G 第一张/最后一张、
  # f 全屏、d 浮层、+/- 缩放、s 切缩放模式、t/T 幻灯片）。这里只补两件事：
  # 深色底 + 启动显示浮层，以及 vim 习惯的 n/N 翻图。
  # 窗口形态在 dotfiles/niri/rules.kdl：app-id="imv" 开浮动 + 80%。
  programs.imv = {
    enable = true;

    settings = {
      options = {
        # 和 noctalia 的纯黑深色主题搭配；看带透明的 PNG 想用棋盘格就写 checks。
        background = "1e1e2e";
        # 启动就显示文件名/分辨率/缩放比例的浮层（d 键可随时开关）。
        overlay = true;
      };

      binds = {
        # imv 默认翻图只有 ←/→（hjkl 都用来平移画面了），按 vim 的 n/N 补上。
        # 特意不动默认的 p：那个是「把当前图片路径打到 stdout」，脚本里要用。
        n = "next";
        "<Shift+n>" = "prev";
      };
    };
  };

  # satty：截图标注工具，只做「打开一张已有图片来画」。这套配置不引入 grim/slurp
  # 那条 wlroots 工具链：截图入口仍然是 niri 内置动作 + noctalia 的
  # screenshot-region / screenshot-annotate（见 AGENTS.md 第 8 节第 5 条）。
  # 想标注刚截的图：Mod+Shift+A 走 dotfiles/niri/scripts/satty-last.sh 打开最新一张。
  # 窗口形态由 niri 决定：dotfiles/niri/rules.kdl 里按 app-id="com.gabm.satty"
  # 配了 open-floating + 80%，所以这里**不要**再开 fullscreen（那会盖掉浮动）。
  # 下面的键按 nixpkgs 26.05 的 satty 0.20.1 写的（0.21 起 early-exit 改成触发器列表，
  # 但 `true` 仍然等价值，升级时留意一下就行）。
  programs.satty = {
    enable = true;

    settings = {
      general = {
        fullscreen = false;
        # 别按图片原始分辨率开窗（2560x1440 的截图就是整屏大），
        # 按「不超过显示器 80%」缩，和 niri 规则里的比例一致。
        # 注意 0.20.1 只认这种内联表写法，`resize = "smart"` 会 TOML 解析报错。
        resize = {
          mode = "smart";
        };
        # Ctrl+C 复制 / Ctrl+S 存盘之后直接退出。
        early-exit = true;
        # 截图最常用的是画箭头；工具快捷键 p/c/b/i/z/r/e/t/m/u/g 都还在。
        initial-tool = "arrow";
        # satty 自己不带剪贴板实现，靠外部命令写 Wayland 剪贴板。
        copy-command = "wl-copy";
        output-filename = "~/Pictures/Screenshots/satty-%Y-%m-%d_%H-%M-%S.png";
        annotation-size-factor = 2;
      };

      # 中文标注用霞鹜文楷（modules/nixos/fonts.nix 装的）。
      font.family = "LXGW WenKai";
    };
  };

  # mpv 本体用 override 挂上 mpris 脚本：裸 mpv 不实现 MPRIS，挂上之后
  # noctalia 的媒体组件（dotfiles/noctalia/config.toml 里的 [widget.media]）
  # 和键盘媒体键才能看到并控制它。yt-dlp 支持是 nixpkgs wrapper 的默认值
  # （youtubeSupport ? true），不用显式打开。
  home.packages = [
    (pkgs.mpv.override {
      scripts = [ pkgs.mpvScripts.mpris ];
    })

    # satty 的 copy-command 要 wl-copy，顺便也给终端里的 wl-copy / wl-paste
    # （以及别的要写剪贴板的脚本）用。
    pkgs.wl-clipboard
  ];

  # mpv 只软链这两个文件，**不**整目录软链：mpv 会把播放进度写在
  # ~/.config/mpv/watch_later/ 下，整目录软链的话这些状态文件会掉进仓库里。
  # 单文件 out-of-store 软链改完存盘即生效，不用 rebuild（和 ghostty 的 config 一样）。
  xdg.configFile."mpv/mpv.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/mpv/mpv.conf";
  xdg.configFile."mpv/input.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/mpv/input.conf";

  # 装了 imv 之后可以用 `xdg-mime default imv.desktop image/png` 之类把它设成
  # 图片默认打开方式。没有写进配置是因为 ~/.config/mimeapps.list 是仓库外的手工文件
  # （现在 image/png 被 Chrome 占着），HM 的 xdg.mimeApps 会直接和它撞车。
}
