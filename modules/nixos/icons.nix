{ pkgs, ... }:

{
  # 图标主题本体必须真的存在，按名字查图标才查得到。
  #   WARN: Could not load icon "fcitx-rime" at size QSize(32, 32) from request
  # 托盘栏在，但图标是空白/不显示。装齐主题后名字能解析，托盘图标才会出来。
  environment.systemPackages = with pkgs; [
    papirus-icon-theme # startup.kdl / settings.ini 里写的 Papirus
    adwaita-icon-theme # 兜住标准名与 symbolic 图标（部分主题的 Inherits 目标）

    glib
    gsettings-desktop-schemas # 只有命令没有 schema 时 gsettings 会报 No such schema
  ];
}
