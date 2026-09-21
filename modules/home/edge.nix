{ pkgs, ... }:

{
  # 容器 / k8s 工具链。抓包那两个（tcpdump / wireshark）不在这里：它们要 setcap wrapper
  # 和用户组，属于系统层，见 modules/nixos/packet-capture.nix。
  #
  # k9s 有 home-manager 模块（生成 ~/.config/k9s/*.yaml），所以走 programs.k9s；
  # 26.05 的 home-manager 里没有 programs.helm / programs.kubectl，podman 那个
  # services.podman 又是另一套（见下），剩下的一律退到 home.packages。
  programs.k9s = {
    enable = true;

    settings.k9s = {
      # 默认 2 秒一次全量刷新。集群多半在远端、kubectl 还要走 clash 代理
      # （见 modules/nixos/clash-verge.nix），每次刷新就是一轮 API 往返，
      # 放宽到 5 秒能少打一半无用请求。
      refreshRate = 5;

      # 表格列多，滚轮翻比记 gg/G 顺手；niri 直接把滚轮事件给窗口，不用按修饰键。
      ui.enableMouse = true;
    };
  };

  # podman 只当 rootless 容器引擎用，和本机已有的 docker（modules/nixos/docker.nix）并存
  # —— 两者 socket、存储目录都不同，不会互相抢。
  # HM 的 services.podman 会把 rootless 真正要读的四份配置写到
  # ~/.config/containers/{policy.json,registries.conf,storage.conf,containers.conf}；
  # rootless podman 优先读 ~/.config/containers 而不是 /etc/containers，所以**不需要**
  # 系统层的 virtualisation.podman（那个是给系统级 podman / docker socket 用的）。
  # 两个前提本机已经满足：/etc/subuid、/etc/subgid 里有 keith:100000:65536
  # （users-groups.nix 给普通用户默认 autoSubUidGidRange），/run/wrappers/bin 里有
  # setuid 的 newuidmap / newgidmap。
  # 刻意**不**开 dockerCompat / dockerSocket：那两个在系统层，而且会和 docker 抢
  # /var/run/docker.sock。以后要用声明式容器（quadlet）就在这儿加
  # services.podman.containers / images / volumes / networks。
  services.podman.enable = true;

  home.packages = with pkgs; [
    # k8s 包管理器。没有配置文件，仓库地址和 context 走命令行或 KUBECONFIG；
    # 插件用 `helm plugin install` 装在 ~/.local/share/helm/plugins（仓库外的手工状态）。
    helm

    # kubectl 自己不带 context / namespace 切换，kubectx 一条命令搞定（含 kubens）；
    # kubectl-convert 把废弃 API 版本的老 yaml 转成新版本，啃老 chart 时用来定位要改的地方。
    # 凭据（~/.kube/config、各种 token）不进仓库，也不在这里生成。
    kubectl
    kubectl-convert
    kubectx
  ];
}
