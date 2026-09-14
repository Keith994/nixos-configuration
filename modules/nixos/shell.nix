{ pkgs, username, ... }:

{
  # NixOS 层启用 zsh。
  # 即使 Home Manager 也管理 zsh，这层仍建议开启。
  programs.zsh.enable = true;

  # 只把普通用户改成 zsh，不影响 root。
  users.users.${username}.shell = pkgs.zsh;
}
