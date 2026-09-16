{ pkgs, ... }:

{
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

  # copy-command 要的 wl-copy 由 wl-clipboard 提供 —— 这套 flake 之前没装过，
  # 顺便也给终端里的 wl-copy / wl-paste（以及别的要写剪贴板的脚本）用。
  home.packages = with pkgs; [ wl-clipboard ];
}
