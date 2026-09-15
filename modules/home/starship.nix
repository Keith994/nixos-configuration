{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # 必须和下面 xdg.configFile 的落点完全一致：指到不存在的路径时 starship 会**静默**
    # 回退到内置默认配置（自定义 toml 被整个忽略，提示符看起来"没生效"）。
    configPath = "${config.xdg.configHome}/starship.toml";
  };
  xdg.configFile."starship.toml".source = ./starship.toml;
}
