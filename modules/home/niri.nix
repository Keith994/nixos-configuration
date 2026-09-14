{ ... }:

{
  xdg.configFile."niri" = {
    source = ../../dotfiles/niri;
    recursive = true;
  };
}
