{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    maple-mono.NF-CN
    nerd-fonts.jetbrains-mono
    lxgw-wenkai
  ];
}
