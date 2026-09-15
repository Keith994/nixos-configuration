{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    # 终端 / 界面主字体：Maple Mono NF CN 自带 Nerd Font 图标和中文，ghostty 与
    # dotfiles/fontconfig/fonts.conf 里的 serif/sans-serif/monospace 都指它。
    maple-mono.NF-CN
    nerd-fonts.jetbrains-mono

    # 中文默认字体：霞鹜文楷（family: LXGW WenKai / LXGW WenKai Mono），
    # 由 fonts.conf 里 lang=zh 的三条规则和"常见中文字体别名"映射统一指过来。
    lxgw-wenkai

    # Symbols Nerd Font：fonts.conf 顶部 alias 里 nerd 图标的兜底字体，少了图标会变豆腐块。
    nerd-fonts.symbols-only

    # fonts.conf 里出现的 WenQuanYi / Microsoft YaHei / SimHei / SimSun 都是**占位名**：
    # 那些 match 会把请求 assign 成 LXGW WenKai，所以不需要真装（实测：没安装的 family
    # 一样能被 assign 覆盖）。真要装是 wqy_microhei / wqy_zenhei。
    # 同理不再需要 source-han-sans / source-han-serif —— 中文已经全指霞鹜文楷，
    # 缺字由系统里的 Noto CJK 兜底。
  ];
}
