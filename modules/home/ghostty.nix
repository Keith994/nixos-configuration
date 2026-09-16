{ config, ... }:

{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
  };

  # 整个目录 out-of-store 软链，而不是只链 `ghostty/config` 一个文件。
  # 只链单文件时 ~/.config/ghostty 是**真实目录**，里面只有 config 一条软链，后果有三个：
  # 1. config 里的相对路径是按配置目录解析的（journal 里能看到
  #    `reading configuration file path=/home/keith/.config/ghostty/themes/dankcolors`），
  #    所以 `custom-shader = shader/cursor_warp.glsl` 一直指向不存在的
  #    ~/.config/ghostty/shader/ —— 启动日志里固定一条
  #    `warning(generic_renderer): error loading custom shaders err=error.FileNotFound`，
  #    仓库里那三个 shader 白放；`themes/dankcolors` 读的也是手工拷到仓库外的那份。
  # 2. noctalia 的 ghostty 模板把调色板写到 $XDG_CONFIG_HOME/ghostty/themes/noctalia，
  #    落在**仓库外**，仓库里那份 themes/noctalia 就成了永远不更新的旧快照
  #    （.gitignore 里的那条规则也就白写）。
  # 3. 改配置保存即生效这个好处顺带拿到（外面套一层目录软链，仍然指向工作区）。
  #
  # 注意：和 foot 一样，一旦设了 `programs.ghostty.settings`（或 `.themes`），HM 会想在
  # ghostty/config（ghostty/themes/…）下落文件，和整目录软链冲突 —— 那种情况只能改回单文件链。
  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/ghostty";
}
