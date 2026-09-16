{ pkgs, ... }:

{
  # 图标主题本体必须真的存在，按名字查图标才查得到。
  #   WARN: Could not load icon "fcitx-rime" at size QSize(32, 32) from request
  # 托盘栏在，但图标是空白/不显示。装齐主题后名字能解析，托盘图标才会出来。
  environment.systemPackages = with pkgs; [
    papirus-icon-theme # startup.kdl / settings.ini 里写的 Papirus
    adwaita-icon-theme # 兜住标准名与 symbolic 图标（部分主题的 Inherits 目标）

    # 光标主题。装在 system 级而不是 home.packages，这样 **greeter 用户**也能用
    # （greetd.nix 里 greeter.toml 的 cursor.theme 就指它）。
    # 主题名要和下面这几处字面一致（都是 share/icons/<名字>）：
    #   dotfiles/umbriel/config.toml  [input.cursor].theme + [environment] XCURSOR_THEME
    #   dotfiles/niri/environment.kdl XCURSOR_THEME
    #   modules/nixos/greetd.nix      cursor.theme
    # 变体：Bibata-Modern-Ice 箭头指左上（和经典 X11 光标同向，niri startup.kdl 注释里原本想要的），
    #       Bibata-Modern-Ice-Right 是镜像版（指右上）。
    bibata-cursors

    glib
    gsettings-desktop-schemas # 只有命令没有 schema 时 gsettings 会报 No such schema
  ];
}
