{ pkgs, ... }:

let
  # SqlKit —— geek-fun/sqlkit，Tauri 2（Rust）写的 AI 原生 SQL 客户端，Apache-2.0。
  # nixpkgs 里**没有**这个包（`nix eval nixpkgs#sqlkit` → Did you mean mlkit/polkit/seqkit…），
  # 所以自己解包。上游每个 release 发 rpm / deb / AppImage / dmg / exe 五种，
  # 这里选 **deb**：它是纯 `usr/bin/sqlkit` + desktop + 三个 png，共 17 个文件，
  # 用 dpkg 解一层就完事。AppImage 反而更麻烦（要么 FUSE、要么 --appimage-extract 再猜目录）。
  #
  # 版本 v1.0.1（2026-10-28 发布，是 GitHub 上的 latest）。hash 是我对下载下来的文件算的
  # （GitHub Releases 不提供官方校验和文件，只有同名的 .sig —— Tauri updater 的 minisign
  # 签名，验它需要上游公钥，而 release 页没公布，所以这里以 sha256 pin 为准）。
  sqlkit-deb = pkgs.fetchurl {
    url = "https://github.com/geek-fun/sqlkit/releases/download/v1.0.1/SqlKit_1.0.1_amd64.deb";
    hash = "sha256-JyxN8cxzObmKJfq6Lv2uJ8E11YhgCE/AYzkuCea+V2A=";
  };

  sqlkit = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "sqlkit";
    version = "1.0.1";

    src = sqlkit-deb;

    nativeBuildInputs = [
      pkgs.dpkg # ar + tar 解 deb；比手搓 `ar x` 稳，且 NixOS 上 PATH 里没有 ar
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    # openssl 必须进 buildInputs：deb 里主程序动态链接 libssl.so.3 / libcrypto.so.3，
    # 但 autoPatchelf 在本仓库 nixpkgs 下找不到它们（见构建日志 "not found"），
    # 光靠 wrapper 的 LD_LIBRARY_PATH 补不进去就会在加载阶段直接
    # `error while loading shared libraries: libssl.so.3` —— 于是进程秒退、连窗口都不出。
    # 列进 buildInputs 后 patchelf 会把 openssl 写进 ELF 的 RPATH，运行时才解析得到。
    buildInputs = [ pkgs.gtk3 pkgs.openssl ];

    # Tauri 二进制会引用一些只有运行时才需要的可选库；缺了不影响启动，
    # 整包放行缺失依赖比逐个补库省事（和 dbeaver-ee 同一处理）。
    autoPatchelfIgnoreMissingDeps = [ "*" ];

    dontConfigure = true;
    dontBuild = true;
    sourceRoot = ".";

    unpackPhase = ''
      runHook preUnpack
      mkdir -p build && cd build
      dpkg-deb -x ${finalAttrs.src} .
      cd usr
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share
      cp -r bin/* $out/bin/
      cp -r share/* $out/share/

      # desktop 的 Exec 是裸 `sqlkit %u`，靠 PATH 命中；但 Tauri 应用还需要
      # WEBKIT_DISABLE_DMABUF_RENDERER：niri 这类 wlroots 合成器上 DMA-BUF 渲染
      # 路径容易白屏（WebKitGTK 的老问题，nixpkgs 里的 Tauri 包普遍这么设）。
      #
      # 真身必须先挪到另一个名字下再包 wrapper：deb 里唯一的可执行文件就叫 `sqlkit`，
      # 若直接 `makeWrapper $out/bin/sqlkit $out/bin/sqlkit`（源=目标同一），
      # makeWrapper 会用 bash wrapper 覆盖掉那个 ELF，而 wrapper 最后一行又是
      # `exec ".../bin/sqlkit"` —— 于是它 exec 自己，无限自举、CPU 打满、永远不出窗口。
      # 标准做法（和 nixpkgs 里所有 Tauri 包一致）：把真身改名收进 .sqlkit-wrapped，
      # wrapper 留在 $out/bin/sqlkit 指向它。desktop / mainProgram 命中的仍是这个路径。
      mv $out/bin/sqlkit $out/bin/.sqlkit-wrapped
      makeWrapper $out/bin/.sqlkit-wrapped $out/bin/sqlkit \
        --prefix LD_LIBRARY_PATH : "$out/lib:${
          pkgs.lib.makeLibraryPath [
            pkgs.gtk3
            pkgs.glib
            pkgs.webkitgtk_4_1
            pkgs.libsoup_3
          ]
        }" \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
        --set GDK_BACKEND wayland,x11

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Agentic SQL database manager for 40+ databases";
      homepage = "https://www.geekfun.club/products/sqlkit/";
      changelog = "https://github.com/geek-fun/sqlkit/releases/tag/v${finalAttrs.version}";
      downloadPage = "https://github.com/geek-fun/sqlkit/releases";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.asl20; # 仓库 LICENSE 是 Apache-2.0，不涉及 unfree 白名单
      platforms = [ "x86_64-linux" ];
      mainProgram = "sqlkit";
    };
  });
in
{
  home.packages = [ sqlkit ];
}
