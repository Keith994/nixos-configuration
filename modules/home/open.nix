{
  pkgs,
  ...
}:

let
  # 终端的 `open`：按文件类型挑程序，Linux 上没有 macOS 那个 open。
  #
  # 为什么不直接 alias 成 xdg-open：本机 ~/.config/mimeapps.list 是仓库外的手工文件，
  # 里面只有 image/* 指向 imv、http(s) 指向 Chrome，text/plain / Office / pdf 全都没有
  # 默认项 —— 那些类型 xdg-open 要么静默失败，要么被 Chrome 抢走，看着像"open 没反应"。
  # 所以文本类、音视频、Office 这几条在这里显式写死，xdg-open 只当兜底和 URL 处理器。
  #
  # 为什么 runtimeInputs 里不塞 nvim / mpv / imv / yazi：
  # 它们已经由别的模块装进用户 profile（nvim.nix、media.nix、yazi.nix），而 media.nix 用的
  # 是挂了 mpris 的 `pkgs.mpv.override` —— 在这里再写一份 pkgs.mpv 会多拉一个闭包、还会让
  # `open video.mp4` 起的 mpv 和媒体键看到的那只不是同一份配置。所以改成 PATH 探测，
  # 探测不到就退到 xdg-open，这样从非登录 shell（ssh、cron）调用也不会硬失败。
  openScript = pkgs.writeShellApplication {
    name = "open";

    runtimeInputs = with pkgs; [
      coreutils
      file
      util-linux # setsid
      xdg-utils # xdg-open，兜底与 x-scheme-handler 都靠它
    ];

    text = ''
      usage() {
        cat <<'EOF'
      用法: open <文件|目录|URL>...

      按文件类型选择打开方式（终端里能看的在前台跑，GUI 程序后台拉起）：
        目录                yazi（没装就 ls -A）
        URL                 默认浏览器（xdg-open / x-scheme-handler）
        text/* 与各类源码   $EDITOR（nvim）
        图片                imv
        音视频              mpv
        PDF                 zathura / mupdf / okular / evince
        Office 文档         libreoffice
        其它                xdg-open（最终以 ~/.config/mimeapps.list 为准）

      找不到对应程序时一律回退到 xdg-open。
      EOF
      }

      have() { command -v "$1" >/dev/null 2>&1; }

      # 按优先级挑第一个装了的命令，全都没有时返回非 0（不是打印空串）。
      pick() {
        local c
        for c in "$@"; do
          if have "$c"; then
            printf '%s\n' "$c"
            return 0
          fi
        done
        return 1
      }

      # GUI 程序不该占住终端：新 session + 丢弃 stdio，关掉终端窗口也不影响它。
      # 不用 `&` + disown 是因为 foot/zsh 退出时仍可能把子进程带走。
      spawn() {
        setsid --fork "$@" >/dev/null 2>&1 </dev/null
      }

      fallback() {
        local target=$1
        if have xdg-open; then
          spawn xdg-open "$target"
        else
          printf 'open: 找不到能打开 %s 的程序\n' "$target" >&2
          return 1
        fi
      }

      # 先挑到具体程序，挑不到再交给 mimeapps.list，所以不会出现"点了没反应"。
      launch_gui() {
        local target=$1 bin
        shift
        if bin=$(pick "$@"); then
          spawn "$bin" "$target"
        else
          fallback "$target"
        fi
      }

      open_editor() {
        local target=$1 ed
        if ed=$(pick nvim vim vi); then
          # 前台运行：nvim 是终端程序，后台化会让它拿不到输入。
          command "$ed" "$target"
        else
          fallback "$target"
        fi
      }

      open_one() {
        local target=$1 mime

        # 带 scheme 的一律当 URL / 协议处理器（x-scheme-handler/* 由 mimeapps.list 决定）。
        if [[ $target =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]] || [[ $target =~ ^(mailto|tg|tonsite): ]]; then
          fallback "$target"
          return
        fi

        if [ -d "$target" ]; then
          if have yazi; then
            ( cd "$target" && exec yazi )
          else
            ls -A -- "$target"
          fi
          return
        fi

        if [ ! -e "$target" ]; then
          printf 'open: %s 不存在\n' "$target" >&2
          return 1
        fi

        mime=$(file --brief --mime-type -- "$target")

        case "$mime" in
          # html 算文档但要看渲染结果，交给浏览器。
          text/html | application/xhtml+xml)
            fallback "$target"
            ;;
          # 文本与源码：file 对 .nix / .md / .conf 之类都只报 text/plain，
          # 靠这一条统一进编辑器。inode/x-empty 是空文件（file 不再报 text/*）。
          text/* | application/json | application/ld+json | application/xml | \
            application/javascript | application/ecmascript | application/x-shellscript | \
            application/x-yaml | application/yaml | application/toml | application/sql | \
            inode/x-empty)
            open_editor "$target"
            ;;
          image/*)
            launch_gui "$target" imv
            ;;
          audio/* | video/*)
            launch_gui "$target" mpv
            ;;
          application/pdf | application/postscript)
            launch_gui "$target" zathura mupdf okular evince
            ;;
          application/vnd.openxmlformats-officedocument.* | \
            application/vnd.oasis.opendocument.* | application/msword | \
            application/vnd.ms-excel | application/vnd.ms-powerpoint | application/rtf)
            launch_gui "$target" libreoffice soffice
            ;;
          *)
            fallback "$target"
            ;;
        esac
      }

      if [ "$#" -eq 0 ]; then
        usage
        exit 1
      fi

      rc=0
      for arg in "$@"; do
        case "$arg" in
          -h | --help)
            usage
            continue
            ;;
        esac
        open_one "$arg" || rc=1
      done
      exit "$rc"
    '';
  };
in
{
  home.packages = [ openScript ];
}
