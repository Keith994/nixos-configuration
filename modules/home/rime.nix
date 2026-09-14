{ config, lib, pkgs, ... }:

let
  rimeUserDir = "${config.xdg.dataHome}/fcitx5/rime";
  defaultCustom = ../../dotfiles/rime/default.custom.yaml;
in

{
  # Rime 判断「配置需不需要重新部署」看的是文件 mtime：
  #   librime deployment_tasks.cc: ConfigNeedsUpdate()
  #   会把 build/default.yaml 里记录的 __build_info.timestamps 和源文件当前 mtime 比较。
  # 而 Nix store 里的文件 mtime 恒为 0，改内容不会改 mtime，所以以前用
  # home.file 软链接进去时，改了 default.custom.yaml 再 nixos-rebuild 也不生效
  # （表现为「配置改了但输入法还是旧的」）。
  #
  # 另外 Rime 有时会回写 default.custom.yaml，而指向只读 store 的软链接会导致
  #   config_data.cc: failed to save config to stream.
  #
  # 所以这里改成：内容变化时装一份可写副本过去，并删掉已编译的
  # build/default.yaml，强制下次启动重新合并 default.yaml + default.custom.yaml。
  # 只重新合并配置，不会重建词库，代价很小。
  home.activation.rimeUserConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    rimeDir="${rimeUserDir}"
    src="${defaultCustom}"
    dst="$rimeDir/default.custom.yaml"

    run mkdir -p "$rimeDir"
    if [[ -L "$dst" ]] || ! ${pkgs.diffutils}/bin/cmp -s "$src" "$dst"; then
      run rm -f "$dst"
      run install -m 0644 "$src" "$dst"
      run rm -f "$rimeDir/build/default.yaml"
    fi
  '';
}
