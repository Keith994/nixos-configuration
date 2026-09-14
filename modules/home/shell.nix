{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

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
      nr = "sudo nixos-rebuild switch --flake ~/nix-config#nixos-vm";
      nb = "sudo nixos-rebuild build --flake ~/nix-config#nixos-vm";
      nc = "nix flake check ~/nix-config";

      # 编辑配置
      nixcfg = "cd ~/nix-config";
    };
  };
}
