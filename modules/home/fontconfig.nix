{ ... }:

{
  # fontconfig 会读 $XDG_CONFIG_HOME/fontconfig/fonts.conf —— 这是 /etc/fonts/conf.d/50-user.conf
  # 里 include 的，和 /etc/fonts/fonts.conf 无关（NixOS 生成的那个已经不含 xdg include），所以放用户层就够。
  # 不要改用 fonts.fontconfig.localConf：那是往 /etc/fonts/local.conf 塞 XML 片段，
  # 而这份配置文件带 <fontconfig> 根元素、直接塞进去会变成嵌套的非法 XML。
  xdg.configFile."fontconfig/fonts.conf".source = ../../dotfiles/fontconfig/fonts.conf;
  # 文件里的 <include ignore_missing="yes">conf.d</include> 是相对本文件目录解析的，
  # 于是 Home Manager 生成的 conf.d/10-hm-fonts.conf（home.packages 里字体的 dir 列表）仍然生效。
}
