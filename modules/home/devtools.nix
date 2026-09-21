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
    lazydocker
    trash-cli

    tree-sitter
  ];
}
