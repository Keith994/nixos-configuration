{ ... }:

{
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
        N = "prev";
      };
    };
  };

  # 装了 imv 之后可以用 `xdg-mime default imv.desktop image/png` 之类把它设成
  # 图片默认打开方式。没有写进配置是因为 ~/.config/mimeapps.list 是仓库外的手工文件
  # （现在 image/png 被 Chrome 占着），HM 的 xdg.mimeApps 会直接和它撞车。
}
