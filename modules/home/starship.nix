{ config, lib, ... }:

let
  # 提示符配置的落点。手写的原始版 `starship.toml.orig` 进版本库，
  # 运行中的 `starship.toml` 由 noctalia 注入、被 `.gitignore` 忽略。
  starshipDir = "${config.home.homeDirectory}/nix-config/dotfiles/starship";
in

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
  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${starshipDir}/starship.toml";

  # 运行中那份（starship.toml）每次换壁纸都被 noctalia 重写，所以它不进版本库；
  # 手写内容维护在同目录的 starship.toml.orig。代价是它一旦缺失
  # （新机器、git clean -xdf、手滑删掉），~/.config/starship.toml 就是一条**悬空软链**，
  # starship 会静默回退到内置默认配置、**不报任何错** —— 所以这里补一道"缺失时播种"。
  #
  # 只在 `! -e` 时动手：绝不覆盖 noctalia 已经注入好的内容（那才是运行中的配置）。
  # 想手动把提示符重置回原始版，还是直接 cp 覆盖：
  #   cp dotfiles/starship/starship.toml.orig dotfiles/starship/starship.toml
  home.activation.starshipSeedConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    dst="${starshipDir}/starship.toml"
    if [ ! -e "$dst" ]; then
      run install -m 0644 "${starshipDir}/starship.toml.orig" "$dst"
    fi
  '';
}
