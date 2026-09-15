{ pkgs, ... }:

{
  home.file.".local/bin/nix-update".source = ../../scripts/nix-update.sh;

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

    setOptions = [ "AUTO_CD" ];

    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;

      ignoreDups = true;
      ignoreAllDups = true;
      share = true;

      extended = true;
    };

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        file = "fzf-tab.plugin.zsh";
      }
    ];

    initContent = ''
      # 使用 fzf-tab 接管补全菜单
      zstyle ':completion:*' menu no

      # Tab / Shift-Tab 在候选项之间移动
      zstyle ':fzf-tab:*' fzf-bindings \
        'tab:down' \
        'shift-tab:up'

      # cd 时显示目录预览
      zstyle ':fzf-tab:complete:cd:*' \
        fzf-preview 'eza -1 --color=always $realpath'

      source ~/.ai-api.zsh
    '';

    shellAliases = {
      # 基础
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";

      # Git
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";

      # NixOS
      nr = "sudo nixos-rebuild switch --flake ~/nix-config#nixos-adol";
      nb = "sudo nixos-rebuild build --flake ~/nix-config#nixos-adol";
      nc = "nix flake check ~/nix-config";
      nup = "nix-update";

      vpn = "export http_proxy=http://127.0.0.1:10800; export https_proxy=http://127.0.0.1:10800; export all_proxy=socks5://127.0.0.1:10800";
      unvpn = "unset http_proxy; unset https_proxy; unset all_proxy";

      # 编辑配置
      nixcfg = "cd ~/nix-config";
    };
  };
}
