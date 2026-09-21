{ pkgs, ... }:

{
  # 物联网 / 串口 / MQTT 调试用的命令行工具。都没有配置文件，参数全在命令行，
  # 所以这里只是把包装上。
  home.packages = with pkgs; [
    # MQTT 的 TUI 客户端（主题树、保留消息、发布订阅都在一起），定位类似 k9s 之于 k8s：
    # mqttui --broker mqtt://host:1883 主题。
    mqttui

    # 只要**客户端**（mosquitto_pub / mosquitto_sub），用来连别人的 broker、验证主题和 QoS。
    # 本机常驻 broker 是另一件事，得在 modules/nixos/ 下开 services.mosquitto
    # （要端口、认证文件、持久化目录），现在没开，所以不碰任何服务配置。
    mosquitto

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
}
