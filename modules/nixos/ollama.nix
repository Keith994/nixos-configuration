{ pkgs, ... }:

{
  # Ollama：本地大模型推理服务。这里用 NixOS 原生模块而不是 deploy/ 下的 docker compose：
  # 本机是 AMD Radeon 780M 核显，模块已经处理好了 ROCm 需要的设备权限（/dev/kfd、/dev/dri、
  # render 补充组）和 DynamicUser 沙箱，还直接支持 rocmOverrideGfx；在 docker 里这些都要
  # 手工映射设备、设 HSA_OVERRIDE_GFX_VERSION，反而更容易漏。
  services.ollama = {
    enable = true;

    # 26.05 的模块已经删掉 acceleration 选项，改用 package 选后端。
    # 不要依赖默认的 pkgs.ollama：它只在全局开 nixpkgs.config.rocmSupport 时才等价 rocm，
    # 否则会静默退回 CPU。
    package = pkgs.ollama-rocm;

    # 780M 是 gfx1103，不在 ROCm 官方支持列表里，不覆盖会报 "no compatible GPUs"。
    # 冒充同代独显 gfx1100（11.0.0）是社区对 780M 验证过的做法。
    rocmOverrideGfx = "11.0.0";

    # 只监听回环，和 mosquitto / redis 的取舍一致。需要局域网访问时再改 host 并开 openFirewall。
    host = "127.0.0.1";
    port = 11434;

    environmentVariables = {
      # Ollama 默认会主动丢弃核显（日志：dropping integrated GPU），
      # 不显式开启的话 780M 明明被 ROCm 识别成 gfx1100 也会退回 100% CPU。
      OLLAMA_IGPU_ENABLE = "1";

      # 补全场景会频繁请求；默认 5 分钟卸载后下次输入要重新加载模型，体验很差。
      OLLAMA_KEEP_ALIVE = "30m";
    };

    # 模型默认落在 /var/lib/ollama/models，由 systemd StateDirectory 管理，重启不丢。
    # 刻意不搬到 ~/data/ollama：该目录一旦启用 DynamicUser，bind 路径的属主/权限很容易写不进去。
  };
}