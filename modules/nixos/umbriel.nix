{ inputs, ... }:

{
  imports = [ inputs.umbriel.nixosModules.default ];

  # 系统层只做两件事：装包 + 用 services.displayManager.sessionPackages 注册一个
  # Name=Umbriel 的 wayland 会话（greetd / noctalia-greeter 靠 sessionData.desktops
  # 找到它，见 greetd.nix 里那段注释）。greetd 的 session.default 没动，还是 niri，
  # 所以这里只是 picker 里多出来的一个测试项，niri + Noctalia v5 那条链路零改动。
  programs.umbriel.enable = true;

  # 模块默认还会装 xdg-desktop-portal-umbriel，并往 xdg.portal 里加
  #   - extraPortals += portal
  #   - config.umbriel.default = [ "umbriel" "gtk" ]
  # 这两项都是纯增量：niri 模块写的是 config.niri.*，XDG_CURRENT_DESKTOP=niri 时不受影响，
  # 所以保留默认，umbriel 会话里浏览器共享屏幕 / 截图才有 portal 可用。
  # 只想跑个合成器、不想多编译一个 portal 的话，把下面这行取消注释即可
  # （代价：umbriel 里 portal 截图/共享会缺 backend）。
  # programs.umbriel.portalPackage = null;
}
