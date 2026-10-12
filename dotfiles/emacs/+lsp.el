;;; +lsp.el -*- lexical-binding: t; -*-

(setq +lsp-prompt-to-install-server 'quiet
      lsp-java-save-actions-organize-imports nil
      lsp-java-content-provider-preferred "fernflower")

(setq lsp-java-vmargs '("-Declipse.application=org.eclipse.jdt.ls.core.id1"
                        "-Dosgi.bundles.defaultStartLevel=4"
                        "-Declipse.product=org.eclipse.jdt.ls.core.product"
                        "-Dlombok.disableConfig=true"
                        "-XX:+UseG1GC"
                        "-XX:+UseStringDeduplication"
                        "-XX:MaxGCPauseMillis=200"
                        "-XX:MetaspaceSize=512M"
                        "-XX:MaxMetaspaceSize=1G"
                        "-javaagent:/home/keith/.local/share/nvim/mason/share/jdtls/lombok.jar"
                        "--add-modules=ALL-SYSTEM"
                        "--add-opens" "java.base/java.util=ALL-UNNAMED"
                        "--add-opens" "java.base/java.lang=ALL-UNNAMED"
                        "-Xmx4G"
                        "-Xms256m"))
;; eclipse.jdt.ls needs java 17+
;; Not sure why brew openjdk cannot be recognized by lsp-java, use linux version instead.
;; Install with `sudo yum install java-17-amazon-corretto-devel`
(setq lsp-java-configuration-runtimes `[(:name "JavaSE-21"
                                         :path "/usr/lib/jvm/java-21-openjdk"
                                         :default t)])
(setq lsp-java-java-path "/usr/lib/jvm/java-21-openjdk/bin/java")

(add-hook! 'go-ts-mode-hook
  (setq go-ts-mode-indent-offset 2)
  (setq lsp-enable-file-watchers t)
  (setq tab-width 2))

;; 诊断函数：查看 xref 项目的详细信息
(defun my/debug-xref-items ()
  "Debug xref items to understand the encoding issue."
  (interactive)
  (message (buffer-name))
  (when (string-match-p "\\*xref\\*" (buffer-name))
    (let ((item (xref--item-at-point)))
      (when item
        (message "Summary: %S" (xref-item-summary item))
        (message "Summary bytes: %s" 
                 (mapcar (lambda (c) (format "%d" c)) 
                         (string-to-list (xref-item-summary item))))
        (let ((location (xref-item-location item)))
          (message "Location: %S" location)
          (message "File: %s" (xref-location-group location))
          (message "Line: %s" (xref-location-line location)))))))



(with-eval-after-load 'lsp-mode
  (defun my/fix-encoding-preserving-properties (str)
    "Fix encoding in STR while preserving text properties."
    ;; 检查是否真的需要修复（包含非ASCII字符但不是有效的多字节字符串）
    (if (string-match "[^\x00-\x7F]" str)
        (let* ((props-list nil)
               (fixed-str
                (or (ignore-errors (decode-coding-string str 'utf-8))
                    (ignore-errors (decode-coding-string str 'gbk))
                    (ignore-errors (decode-coding-string str 'gb2312))
                    (ignore-errors (decode-coding-string str 'chinese-iso-8bit))
                    str)))
          ;; 收集原始字符串的所有文本属性
          (setq props-list (text-property-search-all str))
          
          ;; 恢复文本属性到修复后的字符串
          (dolist (prop props-list)
            (let ((start (nth 0 prop))
                  (end (nth 1 prop))
                  (properties (nth 2 prop)))
              ;; 确保位置不超过新字符串的长度
              (when (and (<= start (length fixed-str))
                         (<= end (length fixed-str)))
                (add-text-properties start end properties fixed-str))))
          fixed-str)
      str))

  (defun text-property-search-all (string)
    "Return all text property ranges in STRING.
  Returns a list of (START END PROPERTIES)."
    (let ((pos 0)
          (len (length string))
          (result nil))
      (while (< pos len)
        (let* ((props (text-properties-at pos string))
               (next-change (or (next-property-change pos string) len)))
          (when props
            (push (list pos next-change props) result))
          (setq pos next-change)))
      (nreverse result)))

  (defun my/fix-xref-summary-encoding-carefully (orig-fun &rest args)
    "Fix encoding issues only when necessary."
    (let ((xref-items (apply orig-fun args)))
      (dolist (item xref-items)
        (when (xref-item-p item)
          (let ((summary (xref-item-summary item)))
            (when summary
              (let ((fixed (my/fix-encoding-preserving-properties summary)))
                (when (not (string= summary fixed))
                  (setf (xref-item-summary item) fixed)))))))
      xref-items))

  (advice-add 'lsp--locations-to-xref-items :around #'my/fix-xref-summary-encoding-carefully)
  (add-hook! 'lsp-help-mode-hook (visual-line-mode 1))
  (setq lsp-log-io t
        lsp-diagnostics-provider :t
        lsp-enable-file-watchers nil
        lsp-file-watch-threshold 100
        lsp-headerline-breadcrumb-enable t
        lsp-diagnostics-provider :flycheck
        lsp-headerline-breadcrumb-icons-enable nil
        lsp-headerline-breadcrumb-segments '(file symbols)
        lsp-imenu-index-symbol-kinds '(File Module Namespace Package Class Method Enum Interface
                                       Function Variable Constant Struct Event Operator TypeParameter))
  (dolist (dir '("[/\\\\]\\.ccls-cache\\'"
                 "[/\\\\]\\.mypy_cache\\'"
                 "[/\\\\]\\.pytest_cache\\'"
                 "[/\\\\]\\.cache\\'"
                 "[/\\\\]\\.clwb\\'"
                 "[/\\\\]\\.env\\'"
                 "[/\\\\]__pycache__\\'"
                 "[/\\\\]bazel-bin\\'"
                 "[/\\\\]bazel-code\\'"
                 "[/\\\\]bazel-genfiles\\'"
                 "[/\\\\]bazel-out\\'"
                 "[/\\\\]bazel-testlogs\\'"
                 "[/\\\\]third_party\\'"
                 "[/\\\\]third-party\\'"
                 "[/\\\\]buildtools\\'"
                 "[/\\\\]out\\'"
                 "[/\\\\]build\\'"
                 ))
    (push dir lsp-file-watch-ignored-directories)))

(with-eval-after-load 'lsp-ui
  (setq lsp-ui-doc-enable t
        lsp-lens-enable nil
        lsp-ui-sideline-enable nil
        lsp-ui-doc-include-signature t
        lsp-ui-doc-max-height 15
        lsp-ui-doc-max-width 100))

;; ============================================================================
;; AI & Coding Assistance
;; accept completion from copilot and fallback to company
;; ===========================================================================
(use-package copilot
  :bind (:map copilot-completion-map
              ("M-n" . 'copilot-previous-completion) ;; 默认是 M-p 和 M-n，和 Emacs 的默认快捷键冲突了，所以改成 M-n 和 M-p
              ("M-p" . 'copilot-next-completion)
              ("<tab>" . 'copilot-accept-completion)
              ("C-e" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion))
  :config
  (add-to-list 'copilot-indentation-alist '(prog-mode 2))
  (add-to-list 'copilot-indentation-alist '(org-mode 2)))

;;; https://github.com/blahgeek/emacs-lsp-booster?tab=readme-ov-file
;;; emacs-lsp-booster
(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
         (funcall bytecode))))
   (apply old-fn args)))

(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)                             ; for check lsp-server-present?
             (not (file-remote-p default-directory)) ; see lsp-resolve-final-command, it would add extra shell wrapper
             lsp-use-plists
             (not (functionp 'json-rpc-connection))  ; native json-rpc
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))  ; resolve command from exec-path (in case not found in $PATH)
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))

(define-minor-mode lsp-booster-minor-mode
  "Toggle lsp-booster"
  :init-value nil
  :lighter " lsp-booster"
  (if lsp-booster-minor-mode
      (progn
        (advice-add (if (progn (require 'json)
                               (fboundp 'json-parse-buffer))
                        'json-parse-buffer
                      'json-read)
                    :around #'lsp-booster--advice-json-parse)
        (advice-add 'lsp-resolve-final-command
                    :around #'lsp-booster--advice-final-command))
    (advice-remove (if (progn (require 'json)
                              (fboundp 'json-parse-buffer))
                       'json-parse-buffer
                     'json-read)
                   #'lsp-booster--advice-json-parse)
    (advice-remove 'lsp-resolve-final-command
                   #'lsp-booster--advice-final-command)))
