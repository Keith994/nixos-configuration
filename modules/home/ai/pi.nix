{ pkgs, ... }:

{
  # pi（@mariozechner/pi-coding-agent）：终端 AI 编码代理。
  # nixpkgs 里直接有包（mainProgram = pi），不像 dsh 要走 npx；它只要求
  # Node >= 20.6，nixpkgs 构建的 node 够用，没有 dsh 那套原生 addon 的坑。
  home.packages = [
    pkgs.pi-coding-agent
  ];
}