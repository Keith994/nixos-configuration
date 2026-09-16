{ config, pkgs, ... }:

{
  # mpv 本体用 override 挂上 mpris 脚本：裸 mpv 不实现 MPRIS，挂上之后
  # noctalia 的媒体组件（dotfiles/noctalia/config.toml 里的 [widget.media]）
  # 和键盘媒体键才能看到并控制它。yt-dlp 支持是 nixpkgs wrapper 的默认值
  # （youtubeSupport ? true），不用显式打开。
  home.packages = [
    (pkgs.mpv.override {
      scripts = [ pkgs.mpvScripts.mpris ];
    })
  ];

  # 只软链这两个文件，**不**整目录软链：mpv 会把播放进度写在
  # ~/.config/mpv/watch_later/ 下，整目录软链的话这些状态文件会掉进仓库里。
  # 单文件 out-of-store 软链改完存盘即生效，不用 rebuild（和 ghostty 的 config 一样）。
  xdg.configFile."mpv/mpv.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/mpv/mpv.conf";
  xdg.configFile."mpv/input.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/mpv/input.conf";
}
