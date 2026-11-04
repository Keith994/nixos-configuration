{ pkgs, ... }:

let
  # Another Redis Desktop Manager（ARDM，qishibo/AnotherRedisDesktopManager）：
  # nixpkgs 26.05 和 unstable 里都**没有**这个包，官方只发上游 AppImage，所以就地用
  # appimageTools 打包（和 modules/home/wechat.nix 同一套路）。
  # 注意它跟收费的 Redis Desktop Manager / RESP.app 是两个不同项目，ARDM 是 MIT。
  # 升级 = 改 version + 重跑 nix store prefetch-file 换 hash。
  ardmVersion = "1.7.4";
  ardmSrc = pkgs.fetchurl {
    url = "https://github.com/qishibo/AnotherRedisDesktopManager/releases/download/v${ardmVersion}/Another-Redis-Desktop-Manager-linux-${ardmVersion}-x86_64.AppImage";
    hash = "sha256-CJrmxFkuGoBMONKZzSl50fhMWLpwTXD5yYHPDuv6cxY=";
  };

  ardm = pkgs.appimageTools.wrapType2 {
    pname = "another-redis-desktop-manager";
    version = ardmVersion;
    src = ardmSrc;

    # Electron 应用按 Chromium 的 Ozone 选 Wayland；不设的话会落到 XWayland。
    extraArgs = [ "--ozone-platform-hint=auto" ];

    # 这个 AppImage 的主程序直接链接了 libxshmfence.so.1，但 nixpkgs 的
    # appimageTools.defaultFhsEnvArgs.multiPkgs 里没有它（那份列表抄的是上游
    # pkg2appimage 的 excludelist，漏了这个），不补就会报
    # "error while loading shared libraries: libxshmfence.so.1"。
    # extraPkgs 会被并进 buildFHSEnv 的 targetPkgs，所以单独塞这一个包就行。
    extraPkgs = pkgs': [ pkgs'.libxshmfence ];
  };

  # AppImage 里自带的图标（108KB PNG），在 -extracted 输出的 usr/share/icons 下。
  # 单独 extract 一次复用它，避免从 -bwrap 包装脚本里反推路径。
  ardmIcon =
    "${pkgs.appimageTools.extractType2 {
      pname = "another-redis-desktop-manager";
      version = ardmVersion;
      src = ardmSrc;
    }}/usr/share/icons/hicolor/0x0/apps/another-redis-desktop-manager.png";
in
{
  # 物联网 / 串口 / MQTT 调试用的命令行工具。都没有配置文件，参数全在命令行，
  # 所以这里只是把包装上。
  home.packages = with pkgs; [
    # MQTT 的 TUI 客户端（主题树、保留消息、发布订阅都在一起），定位类似 k9s 之于 k8s：
    # mqttui --broker mqtt://host:1883 主题。
    mqttui

    # 只要**客户端**（mosquitto_pub / mosquitto_sub），用来连别人的 broker、验证主题和 QoS。
    # 本机常驻 broker 走 docker：deploy/mosquitto/ + scripts/mqtt.sh（compose 起的 eclipse-mosquitto:2，
    # 只绑 127.0.0.1:1883）。不用 services.mosquitto —— 那个要端口、认证文件、持久化目录一套系统级配置，
    # 而这份仓库的本地服务全在 docker 里（mysql / redis 同套路，见 deploy/）。
    mosquitto

    # Redis 命令行客户端（redis-cli）。本机常驻 Redis 同样走 docker：deploy/redis/ + scripts/redis.sh
    # （redis:8.10.3，只绑 127.0.0.1:6379，AOF 持久化 + maxmemory 512m allkeys-lru，数据在 ~/data/redis）。
    # 客户端版本别和容器里的 server 差太远。
    redis

    # Redis 的 GUI 客户端（树形浏览 key、Stream/JSON/ProtoBuf 查看器、CLI 标签页、SSH/SSL/Cluster）。
    # 连本机 docker 里的那个直接填 127.0.0.1:6379 即可。命令行名是 another-redis-desktop-manager。
    ardm

    # Modbus RTU / TCP 客户端，读寄存器、调 PLC / 电表 / 变频器：
    # -m rtu -b 9600 -P none -a 1 -t 4 -r 1 -c 10。
    mbpoll

    # 串口终端：picocom -b 115200 /dev/ttyUSB0，退出是 C-a C-x。
    # 设备权限：NixOS 的 udev 规则把 ttyUSB* / ttyACM* 归到 dialout 组，而 keith 不在
    # dialout 里（`id -nG` 只有 wheel / networkmanager 等），所以现在要 `sudo picocom`。
    # 想免 sudo 就在 hosts/nixos-adol/default.nix 的 extraGroups 里加 "dialout" ——
    # 那属于系统层的决定，这里不动。
    picocom

    # 通用双向管道，一个二进制解决一堆临时需求：串口 <-> TCP
    # （socat -d -d pty,raw,echo=0 tcp-listen:2000）、转发 unix socket、临时 TLS 端点、
    # 给不支持代理的程序套一层。
    socat
  ];

  # 桌面图标：niri 里 Mod+D 的启动器 / noctalia 的 app 列表读 ~/.local/share/applications，
  # 而 AppImage 打包出来的包不带 .desktop，所以要自己写一个。
  # 落点是 ~/.local/share/applications/another-redis-desktop-manager.desktop。
  #
  # 几个字段的来历：
  # - Exec 用包装脚本的**绝对 store 路径**，别写裸命令名 —— 启动器不保证继承 shell 的 PATH；
  # - StartupWMClass 必须和上游 .desktop 里的值一致（窗口类名来自 Electron 的 WM_CLASS），
  #   否则启动器会把它当成另一个程序、图标也认不出来，还会多开一个重复条目；
  # - Icon 指向 store 里的 PNG（不是主题图标名），所以不用额外装图标包也能显示。
  xdg.desktopEntries.another-redis-desktop-manager = {
    name = "Another Redis Desktop Manager";
    genericName = "Redis GUI Client";
    comment = "浏览 / 编辑 Redis 里的 key、支持 Stream、JSON、ProtoBuf、Cluster、SSH 与 SSL";
    exec = "${ardm}/bin/another-redis-desktop-manager %U";
    icon = ardmIcon;
    terminal = false;
    categories = [
      "Development"
      "Database"
    ];
    settings = {
      StartupWMClass = "Another Redis Desktop Manager";
    };
  };
}
