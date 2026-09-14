{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    rustc
    cargo
    nodejs
    yarn

    lsof
    lazygit
    trash-cli

    tree-sitter
  ];
}
