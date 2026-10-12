;;; +use-package.el -*- lexical-binding: t; -*-

;; ============================================================================
;; Completion & UI
;; ============================================================================

;;; Corfu Completion
(use-package corfu
  :bind (:map corfu-map
              ("RET" . nil)
              ("TAB" . 'corfu-insert)
              ("<tab>" . 'corfu-insert))
  :config
  (setq corfu-auto-delay 0.2)
  (setq corfu-auto-prefix 2)
  (setq corfu-quit-no-match 'separator)
  (setq corfu-preselect 'first)
  (setq tab-always-indent 'complete)
  ;; 全局启用
  (global-corfu-mode 1))

;; Multiple Cursors
(use-package multiple-cursors
  :defer t
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)))

;; Better Jumper
(add-hook! 'better-jumper-post-jump-hook #'recenter)

;; ============================================================================
;; File Management
;; ============================================================================

;; Dirvish (Enhanced Dired)
(use-package dirvish
  :defer t
  :config
  (setq dirvish-attributes
        '(vc-state file-size nerd-icons collapse subtree-state file-time))
  (setq dirvish-quick-access-entries
        `(("h" "~/" "Home")
          ("c" "~/.config" "config")
          ("d" "~/repo" "dev")
          ("g" "~/repo/github.com/" "github")
          ("D" "~/Downloads" "Downloads")
          ("e" ,doom-user-dir "Doom directory")
          ("E" ,doom-emacs-dir "Emacs directory")))

  (setq dirvish-hide-details '(dired dirvish dirvish-side)
        dirvish-hide-cursor '(dired dirvish dirvish-side)))

;; IBuffer Enhancement
(use-package all-the-icons-ibuffer
  :after ibuffer
  :hook (ibuffer-mode . all-the-icons-ibuffer-mode)
  :config
  (setq-hook! 'ibuffer-hook ibuffer-formats
              '((mark modified read-only locked " "
                 (name 50 18 :left :elide)
                 " "
                 (size 9 -1 :right)
                 " "
                 (mode 16 16 :left :elide)
                 " " filename-and-process)
                (mark " "
                      (name 16 -1)
                      " " filename))))

;; ============================================================================
;; Terminal & Shell
;; ============================================================================

;; Term Mode
(add-hook! 'term-mode-hook
  (setq-local imenu-generic-expression '(("Prompt" "➜\\(.*\\)" 1))))

;; Process Menu
(add-hook! 'process-menu-mode-hook
  (setq-local tabulated-list-format
              [("Process" 30 t)
               ("PID"      7 t)
               ("Status"   7 t)
               ("Buffer"  15 t)
               ("TTY"     12 t)
               ("Command"  0 t)]))

;; ============================================================================
;; Debugging & Development
;; ============================================================================

;; Dape Debugger Configuration
(when (modulep! :tools debugger)
  (use-package dape
    :defer t
    :config
    (setq dape-breakpoint-margin-string "")

    (defun +my/dape-breakpoint-toggle ()
      "Toggle breakpoint and save to project file."
      (interactive)
      (require 'dape)
      (dape-breakpoint-toggle)
      (+go/write-project-breakpoints))

    (defun +my/dape-breakpoint-remove-all ()
      "Remove all breakpoints and save to project file."
      (interactive)
      (require 'dape)
      (dape-breakpoint-remove-all)
      (+go/write-project-breakpoints))

    ;; 配置 Go 调试器
    (setq dape-configs
          (cons `(delve
                  modes (go-mode go-ts-mode)
                  ensure dape-ensure-command
                  fn (dape-config-autoport dape-config-tramp)
                  command "dlv"
                  command-args ("dap" "--listen" "127.0.0.1::autoport")
                  command-insert-stderr t
                  command-cwd (lambda ()
                                (if (string-suffix-p "_test.go" (buffer-name))
                                    default-directory
                                  (dape-cwd)))
                  port :autoport
                  :type "debug"
                  :request "launch"
                  :mode (lambda ()
                          (if (string-suffix-p "_test.go" (buffer-name))
                              "test"
                            "debug"))
                  :program "."
                  :cwd "."
                  :args (lambda ()
                          (if (string-suffix-p "_test.go" (buffer-name))
                              (save-excursion
                                (when (re-search-backward "^func[ \t]+\\(\\(\\w\\|\\s_\\)+\\)" nil t)
                                  (let* ((test-name (match-string 1))
                                         (test-regexp (concat "^" test-name "$")))
                                    `["-test.run" ,test-regexp])))
                            [])))
                (assq-delete-all 'dlv dape-configs)))))

;; ============================================================================
;; Utilities
;; ============================================================================

;; Consult Todo
(use-package consult-todo
  :defer t)

(use-package org-ql
  :defer t)
(use-package org-superstar
             :defer t)

;; Keycast
(use-package keycast
  :defer t)

;; Enable visual-line-mode in compilation buffers
(add-hook! compilation-mode #'visual-line-mode)

;; ============================================================================
;; Language-specific configurations
;; ============================================================================

;; Go language utilities
(with-eval-after-load 'go-ts-mode
  (defun +go/go-alt ()
    "Create or go to the corresponding _test.go file for the current Go file."
    (interactive)
    (let* ((current-file (buffer-file-name))
           (current-dir (file-name-directory current-file))
           (current-name (file-name-nondirectory current-file))
           (test-file-name (if (string-match "_test\\.go$" current-name)
                               ;; 如果当前已经是测试文件，则跳转到源文件
                               (replace-regexp-in-string "_test\\.go$" ".go" current-name)
                             ;; 否则跳转到测试文件
                             (replace-regexp-in-string "\\.go$" "_test.go" current-name)))
           (test-file-path (expand-file-name test-file-name current-dir)))

      (if (file-exists-p test-file-path)
          ;; 文件存在，直接打开
          (find-file test-file-path)
        ;; 文件不存在，询问是否创建
        (when (yes-or-no-p (format "Create test file %s? " test-file-name))
          (find-file test-file-path)
          ;; 自动添加基本的测试模板
          (when (zerop (buffer-size))
            (insert (format "package %s\n\nimport (\n\t\"testing\"\n)\n\n"
                            (go-package-name current-dir)))
            (save-buffer)))))))

(with-eval-after-load 'lsp-java
  (setq +java-project-package-roots (list ".git" 1)))

;; Java language utilities
(add-hook! 'java-ts-mode-hook
  (require 'lsp-java-boot)
  ;; to enable the lenses
  (add-hook! 'lsp-mode-hook #'lsp-lens-mode)
  (add-hook! 'lsp-mode-hook #'lsp-booster-minor-mode)
  (add-hook! 'java-mode-hook #'lsp-java-boot-lens-mode)
  (defun +java/copy-java-class-path ()
    "Copy the fully qualified Java class name to clipboard."
    (interactive)
    (unless (or (eq major-mode 'java-mode)
                (eq major-mode 'java-ts-mode))
      (user-error "Not in a Java buffer"))
    (let* ((package (save-excursion
                      (goto-char (point-min))
                      (when (re-search-forward "^package \\([^;]+\\);" nil t)
                        (match-string 1))))
           (class (save-excursion
                    (goto-char (point-min))
                    (when (re-search-forward "^public \\(?:class\\|interface\\|enum\\) \\([A-Za-z0-9_]+\\)" nil t)
                      (match-string 1))))
           (fqn (if (and package class)
                    (concat package "." class)
                  class)))
      (when fqn
        (kill-new fqn)
        (message "Copied: %s" fqn)))))

;; ============================================================================
;; Emacs Everywhere (Wayland/Niri specific)
;; ============================================================================

(defun my-emacs-everywhere/update-niri-socket ()
  "Update NIRI_SOCKET environment variable for Wayland/Niri."
  (let* ((rundir (format "/run/user/%d/" (user-uid)))
         (sockets (when (file-directory-p rundir)
                    (directory-files rundir nil "^niri.*sock$" t)))
         (socket-file (if (consp sockets)
                          (concat rundir (car sockets))
                        nil)))
    (if socket-file
        (setenv "NIRI_SOCKET" socket-file)
      (message "Could not find an active niri socket"))))

(use-package emacs-everywhere
  :config
  (my-emacs-everywhere/update-niri-socket)
  (setq emacs-everywhere-frame-name-format nil)

  (setq emacs-everywhere-system-configs
        (append emacs-everywhere-system-configs
                '(((wayland . niri)
                   :paste-command (("ydotool" "key" "29:1" "42:1" "47:1" "47:0" "42:0" "29:0"))
                   :copy-command ("sh" "-c" "wl-copy --type \"text/plain\" < %f; rm %f; cliphist list | head -1 | cliphist decode | wl-copy")
                   :focus-command ("niri" "msg" "action" "focus-window" "--id" "%w")
                   :info-function emacs-everywhere--app-info-linux-niri))))

  (defun emacs-everywhere--app-info-linux-niri ()
    "Return information on the current active window, on a Linux Niri session."
    (require 'json)
    (let* ((json-raw (emacs-everywhere--call "niri" "msg" "-j" "focused-window"))
           (is-err (string-prefix-p "Error" json-raw)))
      (if is-err
          (error "[emacs-everywhere] Error in `niri msg -j focused-window' (see *messages*)")
        (let* ((json (json-read-from-string json-raw))
               (wid (cdr (assq 'id json)))
               (window-id (if (numberp wid) (number-to-string wid) wid))
               (window-title (cdr (assq 'title json)))
               (app-name (cdr (assq 'app_id json))))
          (make-emacs-everywhere-app
           :id window-id
           :class app-name
           :title window-title
           :geometry nil))))))


;; ============================================================================
;; AI & Coding Assistance
;; ============================================================================

;; You can limit the conversation context to an Org heading with the command gptel-org-set-topic.
;; GPTel configuration
(use-package gptel
  :config
  (setq gptel-org-branching-context t) ;; each org heading level 1 is a new topic session
  (setf (alist-get 'org-mode gptel-prompt-prefix-alist) "** ") ;; prefix for user messages in org-mode
  (setf (alist-get 'org-mode gptel-response-prefix-alist) "*** @assistant\n") ;; prefix for response in org-mode
  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll) ;; scroll the window automatically as the response is inserted
  ;; (add-hook 'gptel-post-response-functions 'gptel-end-of-response) ;; move the cursor to the next prompt after the response is inserted
  (setopt gptel-use-tools nil)
  (defun gptel-api-key-from-environment (&optional var)
    "Return a lambda function that retrieves an API key from environment variables."
    (lambda ()
      (getenv (or var
                  (thread-first
                    (type-of gptel-backend)
                    (symbol-name)
                    (substring 6)
                    (upcase)
                    (concat "_API_KEY"))))))

  (gptel-make-gh-copilot "Copilot")
  (gptel-make-privategpt "deepseek-coder"
    :protocol "https"
    :host "api.deepseek.com"
    :endpoint "/beta/v1/chat/completions"
    :stream t
    :key (gptel-api-key-from-environment "DEEPSEEK_API_KEY")
    :context t
    :sources nil
    :header (lambda () (when-let* ((key (gptel--get-api-key)))
                         `(("Authorization" . ,(concat "Bearer " key)))))
    :models '(deepseek-coder
              :capabilities (tool)
              :context-window 128
              :input-cost 0.56
              :output-cost 1.68))
  (gptel-make-deepseek "DeepSeek"
    :stream t
    :key (gptel-api-key-from-environment "DEEPSEEK_API_KEY"))
  (setq 
   gptel-backend (gptel-get-backend "DeepSeek")
   gptel-model 'deepseek-chat)
  (gptel-make-preset 'dictionary
    :description "Preset for dicionary tasks"
    :backend "DeepSeek"
    :model 'deepseek-chat
    :tools 'nil
    :system
    "You act as an English Dictionary.

When I send a message in Chinese, translate it into English;
if it's a word, include phonetic transcription. When I send a message in English, translate it into Chinese;
if it's a word, first explain it in English and the input word include phonetic transcription.
Respond concisely.
example:
** technique
*** @assistant
   technique /tekˈniːk/ n. 技巧，技术，方法
** 归一化
*** @assistant
   Normalization  /ˌnɔːrməlaɪˈzeɪʃən/"
    :temperature 0.2)                                   ;sets gptel-temperature
  )

(use-package ragmacs
  :after gptel
  :config
  (setq gptel-tools
        (list ragmacs-manuals
              ragmacs-symbol-manual-node
              ragmacs-manual-node-contents
              ragmacs-function-source
              ragmacs-variable-source))
  :init
  (gptel-make-preset 'introspect
    :pre (lambda () (require 'ragmacs))
    :system
    "You are pair programming with the user in Emacs and on Emacs.

 Your job is to dive into Elisp code and understand the APIs and
 structure of elisp libraries and Emacs.  Use the provided tools to do
 so, but do not make duplicate tool calls for information already
 available in the chat.

 <tone>
 1. Be terse and to the point.  Speak directly.
 2. Explain your reasoning.
 3. Do NOT hedge or qualify.
 4. If you don't know, say you don't know.
 5. Do not offer unprompted advice or clarifications.
 6. Never apologize.
 7. Do NOT summarize your answers.
 </tone>

 <code_generation>
 When generating code:
 1. Always check that functions or variables you use in your code exist.
 2. Also check their calling convention and function-arity before you use them.
 3. Write code that can be tested by evaluation, and offer to evaluate
 code using the `elisp_eval` tool.
 </code_generation>

 <formatting>
 1. When referring to code symbols (variables, functions, tags etc) enclose them in markdown quotes.
    Examples: `read_file`, `getResponse(url, callback)`
    Example: `<details>...</details>`
 2. If you use LaTeX notation, enclose math in \( and \), or \[ and \] delimiters.
 </formatting>"
    :tools '("introspection")))

;; ============================================================================
;; Project Management
;; ============================================================================

;; Clear project list for consultdefault/search-project))
                                        ;(advice-add func :around #'doom-set-jump-a)

;; Icons
;; (use-package! nerd-icons
;;   :commands nerd-icons-install-fonts
;;   )
;; ;; Colorize color names in buffers
;; (use-package! colorful-mode
;;   :diminish
;;   :hook (after-init . global-colorful-mode)
;;   :init (setq colorful-use-prefix t))

;; ;; Child frame
(use-package posframe
  :custom-face
  (child-frame-border ((t (:inherit posframe-border))))
  :hook (after-load-theme . posframe-delete-all)
  :init
  (defface posframe-border
    `((t (:inherit region)))
    "Face used by the `posframe' border."
    :group 'posframe)
  (defvar posframe-border-width 2
    "Default posframe border width.")
  :config
  (with-no-warnings
    (defun my-posframe--prettify-frame (&rest _)
      (set-face-background 'fringe nil posframe--frame))
    (advice-add #'posframe--create-posframe :after #'my-posframe--prettify-frame)

    (defun posframe-poshandler-frame-center-near-bottom (info)
      (cons (/ (- (plist-get info :parent-frame-width)
                  (plist-get info :posframe-width))
               2)
            (/ (+ (plist-get info :parent-frame-height)
                  (* 2 (plist-get info :font-height)))
               2)))))

;; Display vertico in the child frame
;; (use-package vertico-posframe
;;   :functions posframe-poshandler-frame-center-near-bottom
;;   :hook (vertico-mode . vertico-posframe-mode)
;;   :init (setq vertico-posframe-poshandler
;;               #'posframe-poshandler-frame-center-near-bottom
;;               vertico-posframe-parameters
;;               '((left-fringe  . 8)
;;                 (right-fringe . 8))))
(use-package acp)
(use-package agent-shell)

;; (use-package! hydra
;;   :defines (consult-imenu-config posframe-border-width)
;;   :functions 't
;;   :hook ((emacs-lisp-mode  . hydra-add-imenu)
;;          (after-load-theme . hydra-set-posframe-appearance))
;;   :init
;;   (with-eval-after-load 'consult-imenu
;;     (setq consult-imenu-config
;;           '((emacs-lisp-mode :toplevel "Functions"
;;                              :types ((?f "Functions" font-lock-function-name-face)
;;                                      (?h "Hydras"    font-lock-constant-face)
;;                                      (?m "Macros"    font-lock-function-name-face)
;;                                      (?p "Packages"  font-lock-constant-face)
;;                                      (?t "Types"     font-lock-type-face)
;;                                      (?v "Variables" font-lock-variable-name-face))))))

;;   (defun hydra-set-posframe-appearance ()
;;     "Set appearance of hydra."
;;     (when 't
;;       (setq hydra-hint-display-type 'posframe)
;;       (setq hydra-posframe-show-params
;;             `(:left-fringe 8
;;               :right-fringe 8
;;               :internal-border-width ,posframe-border-width
;;               :internal-border-color ,(face-background 'posframe-border nil t)
;;               :background-color ,(face-background 'default nil t)
;;               :foreground-color ,(face-foreground 'default nil t)
;;               :lines-truncate t
;;               :poshandler posframe-poshandler-frame-center-near-bottom))))
;;   (hydra-set-posframe-appearance))


;; (use-package! pretty-hydra
;;   :functions 't
;;   :bind ("<f6>" . toggles-hydra/body)
;;   :hook (emacs-lisp-mode . pretty-hydra-add-imenu)
;;   :init
;;   (defun pretty-hydra-add-imenu ()
;;     "Have hydras in `imenu'."
;;     (add-to-list 'imenu-generic-expression
;;                  '("Hydras" "^.*(\\(pretty-hydra-define\\) \\([a-zA-Z-]+\\)" 2)))

;;   (cl-defun pretty-hydra-title (title &optional icon-type icon-name
;;                                       &key face height v-adjust)
;;     "Add an icon in the hydra title."
;;     (let ((face (or face 'mode-line-emphasis))
;;           (height (or height 1.2))
;;           (v-adjust (or v-adjust 0.0)))
;;       (concat
;;        (when (and 't icon-type icon-name)
;;          (let ((f (intern (format "nerd-icons-%s" icon-type))))
;;            (when (fboundp f)
;;              (concat
;;               (apply f (list icon-name :face face :height height :v-adjust v-adjust))
;;               " "))))
;;        (propertize title 'face face))))
;;   :config
;;   (with-no-warnings
;;     ;; Define hydra for global toggles
;;     (pretty-hydra-define toggles-hydra
;;       (:title (pretty-hydra-title "ToggleMode" 'faicon "nf-fa-toggle_on")
;;        :color amaranth :quit-key ("q" "C-g"))
;;       ("Basic"
;;        (("n" display-line-numbers-mode "line number" :toggle t)
;;         ("e" electric-pair-mode "electric pair *" :toggle t)
;;         ("c" flyspell-mode "spell check" :toggle t)
;;         ("s" prettify-symbols-mode "pretty symbol" :toggle t)
;;         ("b" display-battery-mode "battery *" :toggle t)
;;         ("i" display-time-mode "time *" :toggle t)
;;         ("m" doom-modeline-mode "modern mode-line *" :toggle t))
;;        "Program"
;;        (("f" flycheck-mode "flycheck" :toggle t)
;;         ("W" which-function-mode "current function *" :toggle t)
;;         ("v" global-diff-hl-mode "gutter *" :toggle t)
;;         ("V" diff-hl-flydiff-mode "live gutter *" :toggle t)
;;         ("M" diff-hl-margin-mode "margin gutter *" :toggle t))
;;        )
;;     )
;;   ))
