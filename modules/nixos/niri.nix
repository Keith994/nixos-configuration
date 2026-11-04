{ pkgs, ... }:

{
  programs.niri.enable = true;

  # 确保 PipeWire 和会话管理器可用
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
  };

  xdg.portal = {
    wlr = {
      enable = true;

      settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${pkgs.wmenu}/bin/wmenu -p 'Share monitor:'";

        # 限制共享帧率，降低高刷屏幕的开销
        max_fps = 30;
      };
    };

    # 仅把 ScreenCast 交给 wlr
    # FileChooser / Screenshot / RemoteDesktop 等保持原有路由
    config.niri."org.freedesktop.impl.portal.ScreenCast" = "wlr";
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
