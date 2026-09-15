{ config, ... }:

{
  # 只装 foot / footclient。server 模式刻意不在这里开：dotfiles/niri/startup.kdl 已经用
  # `spawn-sh-at-startup "foot --server"` 拉起一个（Mod+B 的 btop、Mod+E 的 yazi 都靠
  # footclient 连它）。再开 programs.foot.server 等于第二个进程去抢同一个
  # $XDG_RUNTIME_DIR/foot-<WAYLAND_DISPLAY>.sock。
  programs.foot.enable = true;

  # 整目录 out-of-store 软链，而不是 programs.foot.settings 生成 foot.ini（见第 8 节第 13 条）：
  # - 仓库约定真实配置放 dotfiles/，foot.ini 是手写文件，不该被塞进只读 store 路径；
  # - noctalia v5 的 foot 模板（assets/templates/foot/apply.sh）在应用主题时会写两个文件：
  #   新建 ~/.config/foot/themes/noctalia，并往 foot.ini 顶部插一行
  #   `include=~/.config/foot/themes/noctalia`。指向 store 的只读软链会直接写失败
  #   （和 rime 是同一类坑，见第 6 节）；软链到工作区，noctalia 写的文件就落在
  #   dotfiles/foot/ 下，和 dotfiles/ghostty/themes/noctalia 一样可以进版本库。
  # - foot 的 include 只认绝对路径或 ~/ 开头，所以 noctalia 那行写法是对的；相对路径不行。
  # 注意：一旦设了 programs.foot.settings，HM 会想在 foot/foot.ini 落文件，和整目录软链冲突。
  # 另外 foot 只在启动时读一次配置，改完要重启 server（pkill foot 后重登 niri，或手动补一条
  # foot --server）；SIGUSR1/SIGUSR2 只切 [colors-dark]/[colors-light]，不是重载配置。
  xdg.configFile."foot".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/foot";
}
