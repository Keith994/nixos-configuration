;;; +func.el -*- lexical-binding: t; -*-

;;;###autoload
(defun my/delete-to-beginning-of-line ()
  "Delete from point to the beginning of the line."
  (interactive)
  (delete-region (point) (line-beginning-position)))

;;;###autoload
(defun my/consult-find-file-or-projectile ()
  "在projectile项目中查找文件,否则使用consult-find-file"
  (interactive)
  (if (projectile-project-p)
      (projectile-find-file)
    (consult-find)))

;;;###autoload
(defun my/sp-wrap-with-pair ()
  "Wrap region or word with selected pair characters."
  (interactive)
  (let ((key (read-key "Enter a pair character: "))
        (pair-start)
        (pair-end)
        (beg)
        (end))
    (cond
     ((memq key '(?\( ?\< ?\[ ?\{ ?\" ?\' ?\* ?\_ ?\/ ?\+ ?\= ?\~))
      (setq pair-start (char-to-string key))
      (setq pair-end (cond
                      ((eq key ?\() ")")
                      ((eq key ?\<) ">")
                      ((eq key ?\[) "]")
                      ((eq key ?\{) "}")
                      ((eq key ?\") "\"")
                      ((eq key ?\') "'")
                      ((eq key ?\*) "*")
                      ((eq key ?\_) "_")
                      ((eq key ?\/) "/")
                      ((eq key ?\+) "+")
                      ((eq key ?\=) "=")
                      ((eq key ?\~) "~"))))
     (t
      (error "Invalid pair character")))

    (if (use-region-p)
        (progn
          (setq beg (region-beginning))
          (setq end (region-end)))
      (save-excursion
        (forward-word)
        (setq end (point))
        (backward-word)
        (setq beg (point))))

    (save-excursion
      (goto-char end)
      (insert pair-end)
      (goto-char beg)
      (insert pair-start))

    (when (use-region-p)
      (goto-char (+ end (length pair-start) (length pair-end))))))

;;;###autoload
(defun my/async-shell-command-no-window (command)
  "Requisite Documentation"
  (interactive)
  (let
      ((display-buffer-alist
        (list
         (cons
          "\\*Async Shell Command\\*.*"
          (ons #'display-buffer-no-window nil)))))
    (async-shell-command
     command nil nil)))

;;;###autoload
(defadvice my/async-shell-command-no-window (around auto-confirm compile activate)
  (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest args) t))
            ((symbol-function 'y-or-n-p) (lambda (&rest args) t)))
    ad-do-it))

;;;###autoload
(defun my/display-which-function ()
  (interactive)
  (message (which-function)))

;;;###autoload
(defun my/display-which-path ()
  "Display and copy the current file path starting from home directory."
  (interactive)
  (let* ((full-path (buffer-file-name))
         (home-path (expand-file-name "~"))
         (relative-path (if (string-prefix-p home-path full-path)
                            (concat "~" (substring full-path (length home-path)))
                          full-path)))
    (message relative-path)
    (kill-new relative-path)))

;;;###autoload
(defun my/smart-close-window-enhanced ()
  "Smart window/buffer management:
   - Multiple windows: close current window, keep buffer
   - Single window: kill buffer, switch to another buffer
   - Prompt to save if buffer modified"
  (interactive)
  (let ((current-buffer (current-buffer))
        (window-count (length (window-list))))
    
    (if (> window-count 1)
        ;; Multiple windows: close window
        (progn
          (kill-current-buffer)
          (delete-window))
      
      ;; Single window: manage buffer
      (when (buffer-modified-p current-buffer)
        (when (y-or-n-p (format "Save buffer %s? " (buffer-name current-buffer)))
          (save-buffer)))

      (kill-current-buffer))))
;;;###autoload
(defun my/smart-mark-or-expand-region ()
  "智能标记/扩展选区"
  (interactive)
  (if (region-active-p)
      (progn
        ;; 扩展选区
        (if (fboundp 'er/expand-region)
            (er/expand-region 1)
          (message "expand-region 未安装")
          (exchange-point-and-mark))
        ;; 显示扩展后的选区大小
        (message "选区扩展: %d 字符"
                 (abs (- (mark) (point)))))
    ;; 设置新标记
    (set-mark-command nil)
    (message "标记已设置")))

;;;###autoload
(defun  my/smart-upcase-char-or-word ()
  "智能大写当前字符或单词"
  (interactive)
  (if (use-region-p)
      (upcase-region (region-beginning) (region-end)) ;; 如果有选区，转换选区内的文本为大写
    (upcase-char 1))) ;; 否则，大写当前字符

;;;###autoload
(defun my/smart-downcase-char-or-word ()
  "智能小写当前字符或单词"
  (interactive)
  (if (use-region-p)
      (downcase-region (region-beginning) (region-end)) ;; 如果有选区，转换选区内的文本为小写
    (progn
      (downcase-region (point) (progn (forward-char 1) (point)))
      (backward-char 1)))) ;; 否则，小写当前字符

;;;###autoload
(defun my/copy-function-at-point ()
  "复制当前函数内容到剪贴板"
  (interactive)
  (save-excursion
    (mark-defun)
    (kill-ring-save (region-beginning) (region-end))
    (message "函数已复制到剪贴板")))

;; Return the content of the function at point without text properties.
;; This function marks the entire function definition at point, extracts the
;; text content without any text properties, deactivates the mark, and returns
;; the extracted content. It is designed to be used interactively or called
;; from other Lisp code.
;;;###autoload
(defun my/get-current-function-content ()
  "Return the content of the function at point without text properties."
  (interactive)
  (save-excursion
    (mark-defun)
    (let ((content (buffer-substring-no-properties (region-beginning) (region-end))))
      (deactivate-mark)  ; 取消标记
      content)))

;;;###autoload
(defun gptel-add-comment ()
  "Add comments to the current function."
  (interactive)
  (let ((gptel-model 'deepseek-chat)
        (lang (cond
               ((eq major-mode 'go-ts-mode) "golang")
               ((eq major-mode 'emacs-lisp-mode) "emacs")
               ((eq major-mode 'org-mode) "org")
               (t "markdown"))))
    (gptel-request
        (concat "Add appropriate comments to this function\n```" lang "\n"
                (my/get-current-function-content)
                "\n```")
      :system
      (list "Generate reasonable comments for the provided function. Return ONLY the comment text for this function without any additional explanation, or code block, or markdown formatting."
            "Comment style should follow the conventions of the programming language. If the function has parameters, explain them as well.")
      :callback
      (lambda (resp info)
        (if (stringp resp)
            (let ((buf (plist-get info :buffer)))
              (with-current-buffer buf
                (save-excursion
                  (point)
                  (insert resp))))
          (message "Error(%s): did not receive a response from the LLM."
                   (plist-get info :status)))))))

(defvar gptel-lookup--history nil)

;;;###autoload
(defun my/gptel-ask-from-minibuffer (prompt)
  (interactive (list (read-string "Ask ChatGPT: " nil gptel-lookup--history)))
  (when (string= prompt "") (user-error "A prompt is required."))
  (gptel-request
      prompt
    :callback
    (lambda (response info)
      (if (not response)
          (message "gptel-lookup failed with message: %s" (plist-get info :status))
        (with-current-buffer (get-buffer-create "*gptel-lookup*")
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert response))
          (special-mode)
          (display-buffer (current-buffer)
                          `((display-buffer-in-side-window)
                            (side . bottom)
                            (window-height . ,#'fit-window-to-buffer))))))))

;;;###autoload
(defun my/comment-dwim ()
  "Comment region if active, otherwise comment current line.
If already commented, uncomment instead."
  (interactive)
  (if (use-region-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (save-excursion
      (let ((beg (line-beginning-position))
            (end (line-end-position)))
        (comment-or-uncomment-region beg end)))))

;;;###autoload
(defun my/new-scratch-buffer ()
  "Always create a new *scratch* buffer."
  (interactive)
  (let ((buffer-name "*scratch*")
        (counter 1))
    ;; 如果已存在 *scratch* buffer，则生成新名称
    (while (get-buffer buffer-name)
      (setq buffer-name (format "*scratch-%d*" counter))
      (setq counter (1+ counter)))
    ;; 创建新buffer并切换到它
    (switch-to-buffer (get-buffer-create buffer-name))
    ;; 设置初始模式（可选）
    (org-mode)))

;;;###autoload
(defun my/switch-scratch-buffer ()
  "Switch between multiple scratch buffers."
  (interactive)
  (let* ((scratch-buffers (seq-filter (lambda (buf)
                                        (string-match-p "\\*scratch.*\\*" (buffer-name buf)))
                                      (buffer-list)))
         (buffer-names (mapcar #'buffer-name scratch-buffers))
         (selected (completing-read "Switch to scratch buffer: " buffer-names nil t)))
    (when selected
      (switch-to-buffer selected))))

;;;###autoload
(defun my/switch-to-last-open-buffer ()
  "Switch to the most recently visited buffer other than the current one."
  (interactive)
  (switch-to-buffer (other-buffer)))

;;;###autoload
(defun my/kill-ring-save ()
  "Copy marked region or copy current line."
  (interactive)
  (if (use-region-p)
      (progn
        (kill-ring-save (region-beginning) (region-end))
        (message "Copied region"))
    (progn
      (kill-ring-save (line-beginning-position) (line-end-position))
      (message "Copied current line"))))

;;;###autoload
(defun my/mark-current-line ()
  "Mark the current line."
  (interactive)
  (beginning-of-line)
  (set-mark-command nil)
  (end-of-line))

;;;###autoload
(defun my/python-run-current-script ()
  "Run the current Python script in a shell buffer."
  (interactive)
  (let ((file-name (buffer-file-name)))
    (if file-name
        (progn
          (save-buffer)
          (let ((buffer (get-buffer-create "*Python Output*")))
            (with-current-buffer buffer
              (erase-buffer)
              (insert (format "Running: python %s\n\n" file-name))
              (let ((process (start-process "python-run" buffer "python" file-name)))
                (set-process-sentinel process
                                      (lambda (proc event)
                                        (when (string-match-p "finished" event)
                                          (with-current-buffer buffer
                                            (insert "\nProcess finished."))))))))
          (display-buffer "*Python Output*"))
      (message "Buffer is not visiting a file."))))

;;;###autoload
(defun switch-to-message-buffer ()
  "快速切换到Message的buffer里面。"
  (interactive)
  (let ((buffer (get-buffer "*Messages*")))
    (if buffer
        (switch-to-buffer buffer)
      (message "没有找到Message buffer"))))
