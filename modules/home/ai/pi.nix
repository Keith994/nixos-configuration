{ pkgsUnstable, ... }:

{
  # pi（@mariozechner/pi-coding-agent）：终端 AI 编码代理。
  # 包取自 pkgsUnstable：26.05 的 nixpkgs 里还停在 0.75.4，unstable 才是 1.5.0。
  # 和 wechat 一样属于「单个包吃 unstable」（见 AGENTS.md 第 8 节第 17 条）：
  # 它 MIT、不涉及 unfree 放行；unstable 的产物在 cache.nixos.org 上，不会本地编译。
  # mainProgram = pi，不像 dsh 要走 npx；只要求 Node >= 20.6，没有 dsh 那套原生 addon 的坑。
  home.packages = [
    pkgsUnstable.pi-coding-agent
  ];
}