{ pkgs, ... }:

let
  # DBeaver **Enterprise Edition** 24.0.0。
  #
  # 为什么不直接用 nixpkgs 的 `dbeaver-bin`：那个包写死了 CE（Community）——
  #   url = github.com/dbeaver/dbeaver/releases/.../dbeaver-ce-${version}-linux-x86_64.tar.gz
  # 而 CE 和 EE 是两个不同的发行物：EE 不在 GitHub releases 上，走的是
  # downloads.dbeaver.net/enterprise/<ver>/。另外 dbeaver-bin 锁的是 26.2.0，
  # 这里要的是 **24.0**。所以只能自己起一个 derivation，但 installPhase 照抄
  # dbeaver-bin 那套已经验证过的写法（substitute desktop、删 jre/、autoPatchelf）。
  #
  # 版本只有 24.0.**0** 可选：dbeaver.com/files/ 的 EE 归档每个 minor 只留 `.0`
  # （24.0.0 / 24.1.0 / 24.2.0 / 24.3.0），没有 CE 那边的 24.0.1…24.0.5。
  # 归档索引 https://dbeaver.com/files/24.0.0/ 里列出的就是下面这个 URL。
  #
  # sha256 取自官方 checksum 目录（不是我自己算完就信）：
  #   https://downloads.dbeaver.net/enterprise/24.0.0/checksum/dbeaver-ee-24.0.0-linux.gtk.x86_64.tar.gz.sha256
  #     = b2e439b8ad9c13144112cebfe44f4c2d654a9a05e76769e1c1732d7cbd1710b7
  # 实测整包流式 sha256 与它逐字节一致，转成 SRI 就是下面这行。
  #
  # 两个变体的取舍：tarball 有带 JRE 和不带 JRE（-nojdk）两种。这里取**带 JRE**的那个，
  # 但仍然把包里的 jre/ 删掉、改用 nixpkgs 的 openjdk21 —— 和 dbeaver-bin 的做法一致：
  # 自带 JRE 是上游编好的第三方二进制，既白占 store 空间，又拿不到安全更新。
  # dbeaver.ini 里 `-Dosgi.requiredJavaVersion=17`，21 满足。
  #
  # **license 不在这份配置里**：EE 是付费闭源产品，装完必须在 GUI 里
  # Help → License → Edit License 填自己的 key（或拷 license.json 到工作区
  # ~/.local/share/DBeaverData/workspace6/general/.dbeaver-dr/）。
  # 没 key 也能启动，但企业版特性（Cloud Sync、NoSQL 高级支持等）是锁住的。
  # 刻意不把 key 写进仓库：AGENTS.md 第 8 节第 1 条，密钥一律不入库。
  #
  # javaagent：dbeaver-agent 24.0 的补丁构建（~/90-github/dbeaver-agent24）。
  # store 只读，改不了包里的 dbeaver.ini，所以这里用 `cp -r --no-preserve=all`
  # 拷一份可写的出来再追加。两个坑：
  #   - `-vmargs` 必须是 ini 的**最后一段**，它后面的行全归 JVM；agent 参数只能
  #     追加在文件末尾（放在 `-vmargs` 之前会被 equinox 当成启动器参数吃掉）。
  #   - `-javaagent:` 冒号后**不能有空格**，路径必须绝对 —— ini 没有变量展开，
  #     相对路径按 dbeaver 二进制所在目录解析，所以 agent jar 的路径被硬编码进
  #     store（重新 mvn package 若换了文件名/位置，要同步改下面这行并 rebuild）。
  agentJar = "/home/keith/90-github/dbeaver-agent24/dbeaver-agent-24.0/target/dbeaver-agent.jar";

  dbeaver-ee = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "dbeaver-ee";
    version = "24.0.0";

    src = pkgs.fetchurl {
      url = "https://downloads.dbeaver.net/enterprise/${finalAttrs.version}/dbeaver-ee-${finalAttrs.version}-linux.gtk.x86_64.tar.gz";
      hash = "sha256-suQ5uK2cExRBEs6/5E9MLWVKmgXnZ2nhwXMtfL0XELc=";
    };

    sourceRoot = "dbeaver";

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.gnused
      pkgs.wrapGAppsHook3
      pkgs.autoPatchelfHook
    ];

    buildInputs = [ pkgs.gtk3 ];

    # 让它去 patchelf 我们给的库，而不是包里的 jre/lib（jre 已被 preInstall 删掉）。
    autoPatchelfIgnoreMissingDeps = [ "*" ];

    dontConfigure = true;
    dontBuild = true;

    preInstall = ''
      # 只留本机架构的 JNA fragment（照抄 dbeaver-bin：其它平台的 .so 纯占空间）。
      shopt -s extglob
      pushd plugins/com.sun.jna_*/com/sun/jna/
      rm -r !(ptr|internal|linux-x86-64)/
      popd

      # 删自带 JRE，用 openjdk21 顶替（见上面注释）。
      rm -r jre/
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/dbeaver-ee $out/bin
      # --no-preserve=all：cp 进 store 本来就要去只读位，顺带让下面的 ini 可改。
      cp -r --no-preserve=all * $out/opt/dbeaver-ee
      # 但 --no-preserve=all 会把 dbeaver 二进制的可执行位也去掉（源文件是 444），
      # makeWrapper 的 assertExecutable 会因此报错。拷完后补回正确权限。
      chmod +x $out/opt/dbeaver-ee/dbeaver

      # 补丁 dbeaver.ini：在末尾（-vmargs 段内）追加 javaagent。
      printf '%s\n' '-javaagent:${agentJar}' >> $out/opt/dbeaver-ee/dbeaver.ini

      makeWrapper $out/opt/dbeaver-ee/dbeaver $out/bin/dbeaver-ee \
        --prefix PATH : "${pkgs.openjdk21}/bin" \
        --set JAVA_HOME "${pkgs.openjdk21.home}" \
        --prefix GIO_EXTRA_MODULES : "${pkgs.glib-networking}/lib/gio/modules" \
        --prefix LD_LIBRARY_PATH : "$out/lib:${
          pkgs.lib.makeLibraryPath [
            pkgs.gtk3
            pkgs.glib
            pkgs.webkitgtk_4_1
            pkgs.glib-networking
          ]
        }"

      mkdir -p $out/share/icons/hicolor/256x256/apps
      ln -s $out/opt/dbeaver-ee/dbeaver.png $out/share/icons/hicolor/256x256/apps/dbeaver-ee.png

      mkdir -p $out/share/applications
      ln -s $out/opt/dbeaver-ee/dbeaver-ee.desktop $out/share/applications/dbeaver-ee.desktop

      # desktop 里写的是 FHS 安装路径（Exec=/usr/share/dbeaver-ee/dbeaver、
      # Icon=/usr/share/dbeaver-ee/dbeaver.png、Path=/usr/share/dbeaver-ee/），
      # 在 NixOS 上不存在，必须改写；Path 直接删掉，留着会让 systemd-run 起不来。
      substituteInPlace $out/opt/dbeaver-ee/dbeaver-ee.desktop \
        --replace-fail "/usr/share/dbeaver-ee/dbeaver.png" "dbeaver-ee" \
        --replace-fail "/usr/share/dbeaver-ee/dbeaver" "$out/bin/dbeaver-ee" \
        --replace-fail "Path=/usr/share/dbeaver-ee/" ""

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Universal Database Manager - Enterprise Edition";
      homepage = "https://dbeaver.com/";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      # EE 是商业闭源授权，不是 asl20（那是 CE 的）。放行 unfree 的地方在 base.nix。
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "dbeaver-ee";
    };
  });
in
{
  home.packages = [ dbeaver-ee ];
}
