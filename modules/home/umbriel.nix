{ config, ... }:

{
  # 配置整个目录 out-of-store 软链到仓库，而不是走上游的 programs.umbriel.settings
  # 或 niri 那样的 store 逐文件软链。原因是 noctalia 会**写**这个目录：
  # share/noctalia/assets/templates/umbriel/apply.sh 会往 config.toml 的 [include]
  # 里插 "noctalia.toml"，模板本身还会渲染出 ~/.config/umbriel/noctalia.toml（调色板）。
  # 只读 store 软链会让那次写入失败（和 rime / foot 是同一类坑，见 AGENTS.md 第 6、8 节）。
  # 软链到工作区后，noctalia 生成的文件就落在 dotfiles/umbriel/ 下，可以进版本库。
  #
  # 也因此没有 import inputs.umbriel.homeModules.default：
  # - 它的 programs.umbriel.settings 只能写单文件 config.toml，挡不住 [include] 引用的同目录文件；
  # - 它还会把 umbriel 包装进 home.packages，而包已经由 modules/nixos/umbriel.nix 系统级安装。
  # umbriel 自己会热重载配置文件，所以改 dotfiles/umbriel/*.toml 也不用 rebuild。
  xdg.configFile."umbriel".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/umbriel";
}
