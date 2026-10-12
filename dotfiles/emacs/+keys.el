;;; +keys.el --- keybindings --- -*- lexical-binding: t; -*-
;;; Commentary:

;;; Code:
(setq doom-leader-alt-key "")
;; base key binding
;; 快速删除一个单词或选中区域
(define-key global-map (kbd "C-w")
            (lambda ()
              (interactive)
              (if mark-active
                  (kill-region (region-beginning) (region-end))
                (backward-kill-word 1))))
;;; goto-map
(map!
 :map  goto-map
 "<TAB>" 'nil
 :desc "list errors" "e" 'flycheck-display-error-at-point
 :desc "lsp doc" "y" 'lsp-ui-doc-glance
 :desc "avy jump char" "c" 'avy-goto-char-2
 :desc "disable" "M-c" 'nil
 :desc "goto file" "f" '+lookup/file
 :desc "xdg open at point" "x" #'browse-url
 :desc "imenu" "i" 'imenu)
;;; M-] map
(map!
 :prefix "M-]"
 :desc "centaur-tabs forward" "M-]" #'centaur-tabs-forward
 :desc "flymake-goto-next-error" "e" #'flycheck-next-error
 :desc "vc-next-hunk" "g" #'+vc-gutter/next-hunk
 :desc "end of fun" "f" #'end-of-defun)
;;; M-[ map
(map!
 :prefix "M-["
 :desc "centaur-tabs backward" "M-[" #'centaur-tabs-backward
 :desc "vc-previous-hunk" "g" #'+vc-gutter/previous-hunk
 :desc "flymake-goto-previous-error" "e" #'flycheck-previous-error
 :desc "beginning of fun" "f" #'beginning-of-defun)

(map!
 ;;; M- map
 "M-1" #'+workspace/switch-to-0
 "M-2" #'+workspace/switch-to-1
 "M-3" #'+workspace/switch-to-2
 "M-4" #'+workspace/switch-to-3
 "M-5" #'+workspace/switch-to-4
 "M-?" #'+lookup/references
 "M-." #'+lookup/definition
 "M-w" #'my/kill-ring-save
 "M-SPC" #'my/mark-current-line
 "M-_" 'nil
 "M-;" #'my/comment-dwim
 "M-u" 'my/smart-upcase-char-or-word
 "M-l" 'my/smart-downcase-char-or-word
 "M-s" #'avy-goto-char-2 ;; C-RET 快速跳转到单词
 "M-/" #'dabbrev-completion ;; M-/ 动态补全缓冲区单词
 "M-k" #'+lookup/documentation ;; M-k 查看文档
 "M-o" #'copilot-complete ;; M-o copilot补全

 ;;; C- map
 "C-M-." #'+lookup/type-definition
 "C-M-/" #'dabbrev-expand ;; C-M-/ 动态展开缓冲区单词
 "C-M-s" #'my/sp-wrap-with-pair ;; 快速添加括号对
 "C-S-z" #'undo-fu-only-redo ;; C-S-z 重做
 "C-S-l" #'duplicate-line ;; C-S-l 复制当前行
 "C-_" 'nil
 "C-o" #'pop-global-mark ;; C-o 跳回上一个光标位置
 "C-z" #'undo-fu-only-undo ;; C-z 撤销
 "C-." #'repeat ;; C-. 重复执行上一个复杂命令
 "C-r" #'consult-recent-file ;; 最近打开的文件
 "C-s" #'consult-line ;; 搜索当前buffer
 "C--" #'er/contract-region      ;; C-x - 收缩选择区域
 "C-=" #'er/expand-region ;; C-= 扩大选择区域
 ;; "C-u" #'my/delete-to-beginning-of-line ;; C-u 删除到行首
 "C->" #'mc/mark-next-like-this
 "C-<" #'mc/mark-previous-like-this
 "C-SPC" #'my/smart-mark-or-expand-region
 )

;; M- key binding

;;; C-x disable key binding
(dolist
    (key '("+" "*" "#" "$" "'" "\\" "]" "[" "." "f" ";" "^" "`"
           "B" "C-M-+" "C-M--" "C-M-0" "C-M-=" "z" "X" "w" "n"
           "C-@" "6" "l" "C-z" "t"))
  (global-unset-key (kbd (concat "C-x " key))))
;;; disable winum-keymap
(map! :map winum-keymap "C-x w" nil)
;;; C-x
(map!
 :prefix "C-x"
 "C->" #'mc/mark-all-like-this
 :desc "query replace" "%" #'query-replace-regexp
 "k" 'my/smart-close-window-enhanced
 "9" 'doom/window-enlargen    ;; C-x 9 增大当前窗口
 "S" #'doom/sudo-save-buffer  ;; C-x S 以管理员权限保存文件
 "/" #'+vterm/toggle
 "=" #'balance-windows
 "M-s" #'save-some-buffers
 (:prefix
  ;;; C-x f
  "f"
  :desc "find note" "n" #'+default/browse-notes
  :desc "find file" "f" #'my/consult-find-file-or-projectile ;; C-x f f 打开文件
  :desc "jump to bookmark" "b" #'consult-bookmark ;; C-x f b 跳转到书签
  :desc "open config file" "c" #'doom/open-private-config ;; C-x f c 打开配置文件
  :desc "open dotfile" "d" #'doom/open-dotfile ;; C-x f d 打开dotfile
  :desc "open org-roam file" "o" #'org-roam-node-find ;; C-x f o 打开org-roam文件
  :desc "delete this file" "D" #'doom/delete-this-file ;; C-x f D 删除当前文件
  :desc "rename this file" "R" #'rename-file ;; C-x f r 重命名当前文件
  )
 (:prefix
  ;;; C-x g
  "g"
  :desc "magit status" "g" #'magit-status ;; C-x g g 打开magit状态
  :desc "magit dispatch" "d" #'magit-dispatch ;; C-x g d 打开magit调度
  :desc "magit pull" "p" #'magit-pull ;; C-x g p 拉取最新代码
  :desc "magit push" "P" #'magit-push ;; C-x g P 推送代码
  :desc "magit fetch" "f" #'magit-fetch ;; C-x g f 获取远程更新
  :desc "magit fixtup" "F" #'magit-commit-fixup ;; C-x g F 修复提交
  :desc "magit branch" "b" #'magit-branch ;; C-x g b 管理分支
  :desc "magit checkout" "c" #'magit-checkout ;; C-x g c 切换分支
  :desc "magit log" "l" #'magit-log ;; C-x g l 查看提交日志
  :desc "stage-hunk" "s" #'+vc-gutter/next-h
  :desc "revert-hunk" "r" #'+vc-gutter/revert-hunk
  :desc "hunk diff preview" "p" #'diff-hl-show-hunk
  )
 (:prefix
  ;;; C-x i
  "i"
  :desc "insert emoji" "e" #'emoji-search
  :desc "insert char" "c" #'insert-char
  :desc "insert file" "f" #'insert-file
  :desc "insert unicode" "y" #'+default/yank-pop)
 (:prefix
  ;;; C-x p
  "p"
  :desc "switch project" "p" #'projectile-switch-project ;; C-x p p 切换项目
  :desc "find files" "f" #'projectile-find-file ;; C-x p f 在项目中查找文件
  :desc "search" "s" #'consult-ripgrep  ;; C-x p s 在项目中搜索文本
  :desc "switch buffer" "b" #'projectile-switch-to-buffer ;; C-x p b 切换项目buffer
  :desc "kill buffers" "k" #'projectile-kill-buffers ;; C-x p k 杀死项目buffer
  :desc "add project" "a" #'projectile-add-known-project ;; C-x p a 添加已知项目
  :desc "remove project" "d" #'projectile-remove-known-project ;; C-x p d 移除已知项目
  :desc "invalidate cache" "i" #'projectile-invalidate-cache ;; C-x p i 使项目缓存失效
  :desc "comple" "c" #'projectile-compile-project ;; C-x p c 编译项目
  :desc "run" "x" #'projectile-run-project ;; C-x p x 运行
  :desc "edit local vars" "e" #'projectile-edit-dir-locals ;; C-x p e 编辑项目本地变量
  :desc "search project files" "SPC" #'projectile-find-file ;; C-x p SPC 在项目文件中搜索
  :desc "index project" "I" #'projectile-index-project ;; C-x p I 索引项目
  :desc "replace" "R" #'projectile-replace) ;; C-x p R 替换文本
 (:prefix
  ;;; C-x w
  "w"
  :desc "split window right" "v" #'split-window-right ;; C-x w s 符合vim习惯
  :desc "save session" "s" #'+workspace/save ;; C-x W s 保存工作区
  :desc "load session" "l" #'+workspace/load ;; C-x W l 加载工作区
  :desc "recover last session" "r" #'+workspace/restore-last-session ;; C-x w r 回复最后一次会话
  :desc "rename workspace" "R" #'+workspace/rename ;; C-x w R 重命名工作区
  :desc "new workspace" "n" #'+workspace/new ;; C-x W n 新建工作区
  :desc "kill workspace" "k" #'+workspace/kill ;; C-x W d 删除工作区
  :desc "display workspaces" "i" #'+workspace/display ;; C-x W i 显示工作区列表
  :desc "next workspace" "w" #'+workspace/switch-to ;; C-x w w 切换到下一个工作区
  )
 (:prefix
  ;;; C-x n
  "n"
  :desc "browse notes" "b" #'+default/browse-notes ;; C-x n b 浏览笔记
  :desc "agender" "a" #'org-agenda
  :desc "capture" "c" #'org-capture
  :desc "roam buffer toggle" "l" #'org-roam-buffer-toggle
  :desc "roam node find" "f" #'org-roam-node-find
  :desc "roam node insert" "i" #'org-roam-node-insert
  :desc "daily note" "d" #'org-roam-dailies-capture-today
  :desc "todo" "t" #'org-todo-list)
 (:prefix
  ;;; C-x t
  "t"
  :desc "toggle flycheck" "f" #'flycheck-mode
  :desc "toggle display-line-numbers-mode" "l" #'display-line-numbers-mode
  :desc "toggle wrap" "w" #'toggle-truncate-lines
  :desc "toggle indent guide" "i" #'highlight-indent-mode)
 (:prefix
  ;;; C-x b
  "b"
  :desc "message buffer" "m" #'switch-to-message-buffer
  :desc "switch buffer" "b" #'+vertico/switch-workspace-buffer
  :desc "project buffer" "p" #'projectile-switch-to-buffer
  :desc "new buffer" "n" #'my/new-scratch-buffer ;; 新建一个buffer
  :desc "scratchs buffers" "s" #'my/switch-scratch-buffer
  :desc "last open buffer" "l" #'my/switch-to-last-open-buffer
  :desc "kill buffer" "k" #'kill-this-buffer ;; C-x b k 关闭当前buffer
  :desc "ibuffers" "i" #'ibuffer ;; C-x b i 列出所有buffer
  :desc "revert buffer" "r" #'revert-buffer ;; C-x b r 刷新当前buffer
  :desc "kill other buffers" "c" #'doom/kill-other-buffers ;; C-x b o 关闭其他buffer
  :desc "open project scratch buffer" "x" #'doom/open-project-scratch-buffer ;; C-x b x 打开scratch buffer
  :desc "open scratch" "o" #'doom/toggle-scratch-buffer
  :desc "rename buffer" "R" #'rename-buffer
  )
 (:prefix
  ;;; C-x m
  "m"
  :desc "mark current line" "l" #'my/mark-current-line
  :desc "consult mark" "m" #'consult-mark ;; C-x m m 跳转到标记
  :desc "consult global mark" "g" #'consult-global-mark ;; C-x m g 全局标记
  :desc "consult bookmark" "b" #'consult-bookmark ;; C-x m b 书签
  )
 (:prefix
  ;;; C-x a
  "a" ;; make menu selection persistent across this Emacs session by pressing C-x C-s:
  :desc "open llm buffer" "RET" #'gptel
  :desc "read preset" "p" #'gptel--read-apply-preset
  :desc "set org topic" "t" #'gptel-org-set-topic ;; C-x a t 设置org topic
  :desc "send message" "s" #'gptel-send
  :desc "quick explain" "e" #'gptel-quick
  :desc "open menu" "m" #'gptel-menu
  :desc "add file" "f" #'gptel-add-file
  :desc "add comment at point" "c" #'gptel-add-comment
  :desc "add buffer" "b" #'gptel-add
  :desc "rewrite with response" "r" #'gptel-rewrite
  :desc "one shot question" "a" #'my/gptel-ask-from-minibuffer
  :desc "move to next prompt" "C-e" #'gptel-end-of-response
  :desc "stop response" "S" #'gptel-abort)
 (:prefix
  ;;; C-x A
  "A"
  :desc "agent shell" "RET" #'agent-shell
  :desc "toggle" "t" #'agent-shell-toggle
  :desc "send file" "f" #'agent-shell-send-file
  :desc "send region" "r" #'agent-shell-send-region)
 (:prefix
  ;;; C-x s
  "s"
  :desc "consult ripgrep" "s" #'consult-buffer ;; C-x s s 在项目中搜索文本
  :desc "consult grep" "g" #'consult-ripgrep ;; C-x s g 使用grep搜索文本
  :desc "consult imenu" "i" #'consult-imenu ;; C-x s i 跳转到符号
  :desc "consult line" "l" #'consult-line ;; C-x s l 搜索当前buffer
  :desc "consult multi-occur" "o" #'consult-multi-occur ;; C-x s o 多buffer搜索
  :desc "search and jump file" "f" #'+lookup/file ;; C-x s f 跳转到文件
  ))
;;; org-mode-map
(with-eval-after-load 'org
  (map! :map org-mode-map
        (:prefix
         "C-x"
         (:prefix
          "n"
          :desc "browse notes" "b" #'+default/browse-notes
          :desc "okr file" "k" #'my/open-current-quarter-okr
          :desc "org-ql-search" "q" 'org-ql-search
          "s" 'nil
          (:prefix
           "n"
           :desc "narrow quit" "q" #'widen
           :desc "narrow to block" "b" #'org-narrow-to-block
           :desc "narrow to element" "e" #'org-narrow-to-subtree
           :desc "narrow to subtree" "s" #'org-narrow-to-subtree))))
  )
(map! "C-x C-k" #'+format/region-or-buffer)

;; (map! :map emacs-lisp-mode-map "C-x C-k" #'+format/region-or-buffer)
;;; C-c key binding
(map! :map persp-mode-map "C-c w" nil)
(map! :map projectile-mode-map "C-c p" nil)

;;; C-c 批量禁用不需要的 C-c 前缀绑定
;; (dolist
;;     (key '("l" "e" "p" "C-b" "i" "M-g"))
;;   (map! :prefix "C-c " key 'nil))

;;; lsp-mode-map
(map!
 :map lsp-mode-map
 "M-a" #'lsp-execute-code-action
 "M-r" #'lsp-rename ;; M-r 重命名符号
 "M-k" #'lsp-ui-doc-glance ;; M-k 查看文档
 "C-c C-k" #'+format/region-or-buffer ;; C-c C-k 格式化代码
 "M-?" #'lsp-find-references ;; M-? 查找引用
 "M-." #'lsp-find-definition ;; M-. 跳转定义
 ;;"M-i" #'lsp-imp ;; 查找实现，有冲突
 "C-M-." #'lsp-find-type-definition
 "<f9>"  #'dape-breakpoint-toggle
 "<f10>" #'dape-next
 "<f11>" #'dape-step-in
 "C-<f11>" #'dape-step-out
 "<f5>"  (lambda () (interactive)
           (if (dape-active-mode)
               (dape-continue)
             (dape)))
 "<S-f5>" #'dape-quit
 "C-<f10>" #'dape-until
 (:prefix
  "C-c"
  (:prefix
   "l"
   :desc "workspace symbol" "S" #'consult-lsp-symbols
   :desc "buffer symbol" "s" #'lsp-ui-imenu
   :desc "workspace diagnostics" "W" #'consult-lsp-diagnostics
   :desc "buffer diagnostics" "w" #'consult-lsp-file-diagnostics)))
;;; json-mode-map
(map!
 :map json-mode-map
 :desc "fold toggle" "C-c TAB" #'+fold/toggle
 :desc "beautify json" "C-c C-k" #'json-mode-beautify
 :desc "nullify sexp" "C-c C-f" #'json-nullify-sexp
 :desc "increase number at point" "C-c C-i" #'json-increment-number-at-point)
;;; python-ts-mode-map
(map!
 :map python-ts-mode-map
 :desc "run project" "C-c C-c" #'my/python-run-current-script)
;;; gptel-mode
(map!
 :mode gptel-mode
 :desc "gptel send" "C-c C-c" #'gptel-send
 :desc "gptel explain" "C-c C-e" #'gptel-end-of-response
 :desc "gptel rewrite" "C-c C-r" #'gptel-rewrite
 :desc "gptel menu" "C-c C-m" #'gptel-menu
 :desc "gptel open" "C-c C-o" #'gptel)
;;; embark-map
(with-eval-after-load 'embark
  (dolist (map '(embark-identifier-map
                 embark-command-map
                 embark-function-map
                 embark-symbol-map
                 embark-variable-map))
    (define-key (symbol-value map) (kbd "i") #'+lookup/implementations)
    (define-key (symbol-value map) (kbd "r") #'+lookup/references)
    (define-key (symbol-value map) (kbd "d") #'+lookup/definition)
    (define-key (symbol-value map) (kbd "D") #'+lookup/type-definition)
    (define-key (symbol-value map) (kbd "k") #'+lookup/documentation))
  (map! :map embark-general-map
        :desc "llm quick explain" "?" #'gptel-quick))
;;; org-mode map
(map! :mode org-mode
      (:prefix "C-c"
               (:prefix "t"
                :desc "new table" "n" 'org-table-create
                :desc "add column" "c" 'org-table-insert-column
                :desc "add row" "r" 'org-table-insert-row
                :desc "delete column" "C" 'org-table-delete-column
                :desc "delete row" "R" 'org-table-kill-row
                :desc "move column left" "h" 'org-table-move-column-left
                :desc "move column right" "l" 'org-table-move-column-right
                :desc "move row up" "k" 'org-table-move-row-up
                :desc "move row down" "j" 'org-table-move-row-down)))
(global-set-key (kbd "C-c i") (lambda () (interactive) (find-file "~/org/inbox.org")))
;;; which-key decribtion
(which-key-add-key-based-replacements
  "C-x RET" "coding system"
  "C-x 4" "open in other window"
  "C-x 5" "open in other frame"
  "C-x 8" "insert special char"
  "C-x 8 e" "insert emoji"
  "C-x >" "view content left"
  "C-x <" "view content right"
  "C-x a" "abbrev"
  "C-x b" "project buffer"
  "C-x x" "font and buffer"
  "C-x r" "registers"
  "C-x K" "kill buffer in all window"
  "C-x p" "projectile"
  "C-x g" "magit"
  "C-x f" "files"
  "C-x i" "insert"
  "C-x t" "toggle"
  "C-x n" "notes"
  "C-x v" "git"
  "C-x b" "buffers"
  "C-x m" "marks/bookmakrs"
  "C-x a" "gptel"
  "C-x s" "search"
  "C-c @" "outlines"
  )
(add-hook! org-mode-hook 'lambda ()
  (which-key-add-key-based-replacements
    "C-c l" "org cmds"
    "C-c i" "inbox"
    "C-c t" "tables"
    )
)

;; tips and tricks
;; emacs模式技巧
;; M-% replace regexp
;; C-M-h 快速标记整个函数
;; 查看按键绑定 C-h k <key>
;; C-M-<end> 跳转到函数末尾
;; C-M-<home> 跳转到函数开头
;; C-M-f 跳转字符串或者括号的下一个位置 C-M-b 跳转字符串或者括号的上一个位置
;; C-M-d
;; C-M-Backspace 删除括号或双引号
;; C-/ undo
;; C-S-/ redo
;; 删除括号或者双引号里面的内容,可以使用embark  C-; Backspace键 也可以连续使用C-space 选择内容后使用C-w删除
;; 使用C-x M-: 查看复杂的传参的函数调用
;; M-i tab
;; M-? reference
;; M-. definition
;; C-S-z redo
;; C-z undo
;; C-; embark-act ;; 对当前光标下的内容执行embark操作
;; C-' avy-goto-char-2 快速跳转到单词
;; M-: ;; 手动执行一个elisp函数
;; C-a C-k C-z ;; 快速复制一行
;; C-a C-k ;; 快速选择一
;; C-x h ;; 快速选择整个buffer
;; C-space C-= ;; 快速选择单词、一行、段落、整个buffer
;; M-u ;; 大写一个字符
;; M-l ;; 小写一个字符
;; M-g M-g ;; 快速跳转行
;; C-` ;; +popup/toggle 切换弹框buffer
;; C-M 键位适配
;; C-M-n 向下跳转符号
;; (buffer-substring-no-properties (point-min) (point-max))   获取整个缓冲区的内容
;; (save-excursion (mark-defun) (buffer-substring-no-properties (region-beginning) (region-end)) 获取当前函数的内容)
;; (buffer-substring-no-properties (save-excursion (beginning-of-defun) (point)) (save-excursion (end-of-defun) (point)))
