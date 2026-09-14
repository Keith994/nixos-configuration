{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    configPath = "${config.xdg.configHome}/starship/starship.toml";
  };
  xdg.configFile."starship.toml".source =  ./starship.toml;
}
