{ pkgs, ... }:

let
  # clash-verge 的 mixed-port（= clash-verge-rev config.yaml 里的 mixed-port）：HTTP 与 SOCKS5
  # 共用同一个端口，所以 http:// / socks5:// 两种写法都通。全仓库统一成 http://，
  # 免得同一个端口出现两种 scheme（端口值同时被 modules/home/noctalia.nix 引用，改要一起改）。
  proxy = "http://127.0.0.1:10800";

  # 给命令做前缀用的代理环境。只作用于被启动的客户端进程：真正下载 store 路径的是
  # nix-daemon，它不继承这些变量 —— 受益的是 flake 输入抓取（github / api.github.com）这类
  # 客户端侧请求，所以 `sudo env` 这种写法够用。
  proxyEnv = "http_proxy=${proxy} https_proxy=${proxy} all_proxy=${proxy}";

  # 本机与内网不走代理，取值与 modules/home/noctalia.nix 的 noctalia-proxy 保持一致，
  # 否则访问 localhost / 局域网服务也会被塞进 clash。
  noProxy = "localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
in
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
      # nr / nb / nup 走代理：它们会抓 flake 输入。nc 故意不加 —— 输入都在 store 里时它不需要
      # 网络，留一条 clash 没起时也能用的路（代理端口没人监听时，带代理的命令会直接连接失败）。
      nr = "sudo env ${proxyEnv} NO_PROXY=${noProxy} nixos-rebuild switch --flake ~/nix-config#nixos-adol";
      nb = "sudo env ${proxyEnv} NO_PROXY=${noProxy} nixos-rebuild build --flake ~/nix-config#nixos-adol";
      nc = "nix flake check ~/nix-config";
      # nix-update 是 scripts/nix-update.sh 那个脚本：里面 `nix flake lock` 一行会继承这里的
      # 变量，而脚本内部的 `sudo nixos-rebuild` 拿不到（sudo 清环境）。
      nup = "env ${proxyEnv} NO_PROXY=${noProxy} nix-update";

      # vpn / unvpn：只改当前 shell 的环境（不写进会话级环境变量）。
      # 大写那组是给只认大写变量名的程序；NO_PROXY 同上，别让本机和内网走代理。
      vpn = "export http_proxy=${proxy} https_proxy=${proxy} all_proxy=${proxy}; export HTTP_PROXY=${proxy} HTTPS_PROXY=${proxy} ALL_PROXY=${proxy}; export NO_PROXY=${noProxy} no_proxy=${noProxy}";
      unvpn = "unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY no_proxy";

      # 编辑配置
      nixcfg = "cd ~/nix-config";
    };
  };
}
