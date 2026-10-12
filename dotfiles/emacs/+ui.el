;;; +ui.el -*- lexical-binding: t; -*-

;; ============================================================================
;; Theme & Appearance
;; ============================================================================
(setq catppuccin-flavor 'mocha
      doom-theme 'doom-dracula
      +workspaces-on-switch-project-behavior 'non-empty)
(setq doom-font "Maple Mono NF CN-11.5")
(setq doom-font-increment 1)
;;(set-fontset-font "fontset-default" 'han (font-spec :family "WenQuanYi Micro Hei Mono"))

;; =================================n===========================================
;; Window & Buffer Management
;; ============================================================================
;; (set-popup-rules! '(("^\\*helpful" :size 0.35)
;;                     ("^\\*Ibuffer\\*$" :size 0.35)
;;                     ("^\\*info.*" :size 80 :side right)
;;                     ("^\\*Man.*" :size 80 :side right)
;;                     ("^\\*keycast.*" :size 50 :side right)
;;                     ("^\\*Customize" :actions display-buffer)
;;                     ("^\\*edit-indirect" :size 0.6)
;;                     ("^\\*YASnippet Tables\\*$" :size 0.35)
;;                     ("^\\*grep\\*$" :size 0.35)
;;                     ("^\\*pytest\\*" :size 0.35)
;;                     ("^\\*Anaconda\\*$" :size 0.35)
;;                     ("^\\*aider.*$" :ignore t)
;;                     ("\\*Async Shell Command\\*$" :side bottom :size 0.30 :select t)
;;                     ("\\*.*server log\\*$" :side top :size 0.20 :select nil)
;;                     ((lambda (buf _) (with-current-buffer buf (eq major-mode 'forge-topic-mode))) :size 0.35)))
;; Aider specific window placement
; (with-eval-after-load 'aider
;   (add-to-list 'display-buffer-alist
;                '((major-mode . #'aider-comint-mode)
;                  (display-buffer-in-side-window)
;                  (side . right)
;                  (slot . 0)
;                  (window-width . 0.4))))

(set-popup-rules! '(("^\\*Embark Collect:.*\\*$" :side bottom :size 0.30)))

;; ============================================================================
;; Syntax Highlighting & Colors
;; ============================================================================
(defface breakpoint-enabled '((t)) "Breakpoint face.")

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :init
  ;; code here will run immediately
  :config
  ;; code here will run after the package is loaded
  (setq hl-todo-highlight-punctuation ":"))

(with-eval-after-load 'flycheck
  (setq flycheck-auto-display-errors-after-checking nil))


;; ============================================================================
;; Doom Modeline
;; ============================================================================
(setq
 doom-modeline-icon t
 doom-modeline--eglot t
 doom-modeline-buffer-encoding nil
 doom-modeline-window-width-limit (- fill-column 10)
 doom-modeline-vcs-max-length 80
 doom-modeline-major-mode-icon t
 doom-modeline-enable-word-count t
 doom-modeline-buffer-file-name-style 'file-name-with-project
 doom-modeline-minor-modes nil
 )

(defun my/modeline-minor-modes ()
  "Return a short string of selected minor modes for the modeline."
  (let (xs)
    ;; 你想显示哪些 minor mode，就在这里加
    (when (bound-and-true-p copilot-mode) (push "Copilot" xs))
    (setq xs (nreverse xs))
    (when xs
      (propertize
       (concat " " (string-join xs " ") )
       'face '(:foreground "#a3be8c" :weight semi-bold)))))

(with-eval-after-load 'doom-modeline
  (doom-modeline-def-segment my-minor-modes
    "Selected minor modes."
    (my/modeline-minor-modes))

  ;; 把 segment 插入到主 modeline（例如放在右侧靠前）
  ;; 不同 Doom/doom-modeline 版本 layout 名称可能略有不同，
  ;; 常见的是 'main 或 'project 等。
  (doom-modeline-def-modeline 'my-main
    '(bar workspace-name window-number modals matches buffer-info remote-host buffer-position parrot selection-info)
    '(misc-info minor-modes my-minor-modes input-method buffer-encoding major-mode process vcs))

  (defun my/setup-modeline ()
    (doom-modeline-set-modeline 'my-main 'default))
  (add-hook 'doom-modeline-mode-hook #'my/setup-modeline))
