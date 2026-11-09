{ pkgs, ... }:

{
  programs.nix-ld.enable = true;

  # mason 装的 marksman 是 GitHub Releases 里的 .NET 自包含二进制，启动时 dlopen ICU
  # 做全球化支持。NixOS 没有 /usr/lib，而 nix-ld 的默认库集合里也没有 icu，于是它直接
  # "Couldn't find a valid ICU package installed on the system" abort（退出码 134）。
  # 把 icu 塞进 nix-ld 的库目录就行：nix-ld 会把 /run/current-system/sw/share/nix-ld/lib
  # 追加进 LD_LIBRARY_PATH，所有走 nix-ld 的预编译 ELF 都能拿到它（其它 .NET 工具同理）。
  # 别图省事改成 DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1：那会让所有 .NET 程序丢区域/排序
  # 支持，且只在设了变量的进程里生效，属于掩盖问题而不是修好。
  programs.nix-ld.libraries = [ pkgs.icu ];
}
