;; packages.el -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; ============================================================================
;; Disabled Packages
;; ============================================================================

;; Disable unused packages that may conflict with Doom's configurations or are unnecessary
(disable-packages! solaire-mode        ; Unused solarized theme mode
                   osx-trash           ; Mac-specific trash handling (not needed on other OSes)
                   realgud             ; RealGUD debugger (may conflict with built-in debugging)
                   realgud-trepan-ni   ; Trepan-NI backend for RealGUD
                   ccls                ; C/C++ LSP server (replaced by clangd in Doom)
                   tide                ; TypeScript IDE (replaced by ts-ls)
                   swiper              ; Swiper search (replaced by Doom's vertico/ivy)
                   forge               ; Git forge integration (may overlap with magit)
                   code-review         ; Code review tool (not always needed)
                   writegood-mode      ; Writing style checker (optional)
                   dired-x             ; Extra Dired features (Doom has its own dired config)
                   flymake-popon       ; Flymake popon display (replaced by Doom's flycheck)
                   anaconda-mode       ; Python mode (replaced by LSP)
                   company-anaconda    ; Company backend for anaconda (unnecessary with LSP)
                   lsp-python-ms       ; Microsoft Python LSP (replaced by pylsp)
                   pyimport            ; Python import management (handled by other tools)
                   )

;; ============================================================================
;; UI & Appearance
;; ============================================================================
(package! catppuccin-theme)
(package! all-the-icons-ibuffer)
(package! keycast)
(package! multiple-cursors)

;; ============================================================================
;; AI & Coding Assistance
;; ============================================================================
(package! copilot
  :recipe (:host github :repo "copilot-emacs/copilot.el" :files ("*.el")))
(package! posframe)

(package! ragmacs
  :recipe (:host github :repo "positron-solutions/ragmacs" :files ("*.el")))
(package! shell-maker)
(package! acp)
(package! agent-shell)
(package! org-ql)
(package! org-superstar)
;; (package! anki-editor
;;   :recipe (:host github :repo "anki-editor/anki-editor"))
;; (package! jupyter)
;; (package! ein)
;; (package! aider :recipe (:host github :repo "tninja/aider.el"))
;;(unpin! :completnion :ui :editor :emacs :checkers :lang :tools)
;; (package! nerd-icons)
;; (package! colorful-mode)
;; (package! hydra)
;; (package! pretty-hydra)
