{ pkgs, ... }:

{
  # 网络排查 / 联调工具。抓包那两个（tcpdump / wireshark）**不在这里**：它们的正经用途
  # 就是抓包，而抓包要 setcap wrapper + 用户组，属于系统层，见
  # modules/nixos/packet-capture.nix。
  home.packages = with pkgs; [
    # 端口 / 服务 / 版本探测。默认的 TCP connect 扫描（-sT）普通用户就能跑，所以装在
    # 家目录这层没问题；半开扫描（-sS）、OS 指纹（-O）、构造原始包（-PE）要 root，
    # 直接 sudo 即可，不需要 setcap wrapper。ncat（nc 替代）和 nping 同包自带。
    nmap

    # 打带宽 / 丢包。客户端服务端同一个二进制（-s 起服务、-c 连过去）。
    # 本机只当客户端用：base.nix 的 firewall 只放行了 localsend 的 53317，没放 5201，
    # 要当服务端收数据得先在 base.nix 放行。
    iperf3

    # gRPC 的 curl。服务开了 server reflection 就能 `grpcurl -plaintext host:port list`
    # 列服务、调方法，不用写客户端；没开 reflection 就自己 -proto 指 .proto 文件
    # （配合 -import-path）。
    grpcurl
  ];
}
