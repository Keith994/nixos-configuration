{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # 必须和下面 xdg.configFile 的落点完全一致：指到不存在的路径时 starship 会**静默**
    # 回退到内置默认配置（自定义 toml 被整个忽略，提示符看起来"没生效"）。
    configPath = "${config.xdg.configHome}/starship.toml";
  };

  # 用 out-of-store 软链而不是普通 source（store 只读软链），原因是 **noctalia 要写它**：
  # 主题模板里的 "starship"（state 层 builtin_ids 里有）先把调色板渲染到
  # $XDG_CACHE_HOME/noctalia/starship-palette.toml，再由它的 apply.sh 把
  # `palette = "noctalia"` + 带 marker 的调色板块合并进 ~/.config/starship.toml ——
  # 脚本明确是"写穿软链"（cat > "$config_file"），指向 store 就报
  # 「只读文件系统」，日志里 [hook_runner] hook failed 刷了十几条。
  # 和 rime / foot / nvim 是同一类坑（见 AGENTS.md 第 5、6 节）。
  #
  # 代价：starship 没有 include 机制，那段调色板只能内联进这个文件，所以每次换主题
  # 都会改写它的内容（`dotfiles/starship/starship.toml` 会变脏）。它既是手写配置、
  # 又是 noctalia 的渲染目标，所以照旧进版本库，看 diff 决定要不要提交 ——
  # 这点和那些"纯生成物"（被 .gitignore 忽略的 noctalia.kdl / themes/noctalia）不同。
  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/dotfiles/starship/starship.toml";
}
