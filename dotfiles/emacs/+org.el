;;; +org.el -*- lexical-binding: t; -*-
(with-eval-after-load 'org
  (setq org-startup-folded 'overview)
  (setq org-directory "~/org/"
        org-default-notes-file "~/org/inbox.org"
        org-roam-directory "~/org/roam"
        org-roam-completion-everywhere t)

  ;; 让 refile 可以在所有 agenda 文件中查找目标，不限层级
  (setq org-refile-targets '((org-agenda-files :maxlevel . 2)))
  ;; 显示完整的文件路径，方便区分同名标题
  (setq org-refile-use-outline-path 'file)
  (defun my/org-agenda-files-for-dailies ()
    "返回 agenda 文件列表：当前 daily note + 未来 7 天 + 过去的14天 + OKR 文件"
    (let ((files '()))
      ;; 1. 加入 OKR 文件（固定）
      (setq files (append files (directory-files "~/org/okr/" t "\\.org$")
                          (directory-files "~/org/projects/" t "\\.org$")
                          (list "~/org/inbox.org")))
      ;; 2. 加入当前、未来 7 天和过去 14 天的 daily notes
      (dotimes (i 22)
        (let* ((offset (- i 14))
               (date (format-time-string "%Y-%m-%d" (time-add nil (* offset 86400))))
               (daily-file (expand-file-name (format "roam/daily/%s.org" date) org-directory)))
          (when (file-exists-p daily-file)
            (push daily-file files))))
      files))

  (setq org-agenda-files (my/org-agenda-files-for-dailies))

  (add-to-list 'org-capture-templates
               '("i" "Inbox" entry (file+headline "~/org/inbox.org" "Inbox")
                 "* TODO %?\n  %i\n")
               t)  ; t 表示追加到末尾

  (add-to-list 'org-capture-templates
               '("k" "KR 任务" entry
                 (file+headline "~/org/inbox.org" "Inbox")
                 "*** KR%^{KR编号} %^{KR描述}\n:PROPERTIES:\n:KR_CURRENT: %^{当前进度}\n:ID: %(my/generate-kr-id)\n:END:\n\n"
                 :empty-lines 1)
               t)  ; t 表示追加到末尾
  (defun my/get-current-quarter ()
    "返回当前季度，格式：Q1/Q2/Q3/Q4"
    (let ((month (string-to-number (format-time-string "%m"))))
      (cond ((<= 1 month 3) "Q1")
            ((<= 4 month 6) "Q2")
            ((<= 7 month 9) "Q3")
            (t "Q4"))))

  (defun my/get-current-year ()
    "返回当前年份"
    (format-time-string "%Y"))
  (defun my/generate-kr-id ()
    "生成 KR ID：2026q2-krX"
    (let ((year (my/get-current-year))
          (quarter (downcase (my/get-current-quarter)))
          (kr-num (read-from-minibuffer "KR 编号: ")))
      (format "%s%s-kr%s" year quarter kr-num)))
  (defun my/open-current-quarter-okr ()
    "打开当前季度的 OKR 文件（格式：2026q2.org）"
    (interactive)
    (let* ((year (format-time-string "%Y"))
           (quarter (my/get-current-quarter))  ; 返回 "Q1" "Q2" 等
           (quarter-lower (downcase quarter))   ; 转为 "q1" "q2"
           (filename (format "%s%s.org" year quarter-lower))
           (filepath (expand-file-name filename (expand-file-name "okr" org-directory))))
      (if (file-exists-p filepath)
          (find-file filepath)
        (find-file filepath)
        (insert (format "#+TITLE: %s %s OKRs\n" year quarter))
        (insert (format "#+ID: okr-%s%s\n\n" year quarter))
        (insert (format "* Objective 1\n:PROPERTIES:\n:ID: okr-%s%s-1\n:END:\n" year quarter-lower)))))
  (add-hook 'org-mode-hook (lambda () (flycheck-mode -1)))
  (setq flycheck-global-modes '(not org-mode))
  (add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))
  )
