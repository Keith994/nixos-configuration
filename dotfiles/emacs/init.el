;;; init.el -*- lexical-binding: t; -*-

(doom! ;:lang 
       ;chinese

       :completion
       (corfu +icons +abbrev +orderless)  ; complete with cap(f), cape and a flying feather!
        ;(vertico +icons +childframe)           ; the search engine of the future
       (vertico +icons)           ; the search engine of the future

       :ui
       doom              ; what makes DOOM look the way it does
       hl-todo           ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       indent-guides     ; highlighted indent columns
       ligatures         ; ligatures and symbols to make your code pretty again
       modeline          ; snazzy, Atom-inspired modeline, plus API
       (popup +defaults)   ; tame sudden yet inevitable temporary windows
       smooth-scroll     ; So smooth you won't believe it's not butter
       tabs              ; a tab bar for Emacs
       ;unicode           ; extended unicode support for various languages
       ;;(treeemacs +lsp)
       (vc-gutter +pretty) ; vcs diff in the fringe
       ;;vi-tilde-fringe   ; fringe tildes to mark beyond EOB
       (window-select +numbers)    ; visually switch windows
       workspaces        ; tab emulation, persistence & separate workspaces

       :editor
       file-templates    ; auto-snippets for empty files
       fold              ; (nigh) universal code folding
       (format +lsp)  ; automated prettiness
       snippets          ; my elves. They type so I don't have to
       (whitespace +guess +trim)  ; a butler for your whitespace

       :emacs
       (dired +dirvish +icons)       ; making dired pretty [functional]
       electric          ; smarter, keyword-based electric-indent
       (ibuffer +icons)           ; interactive buffer management
       undo              ; persistent, smarter undo for your inevitable mistakes

       :checkers
       (syntax +childframe +nflycheck)              ; tasing you for every semicolon you forget
       (spell +flyspell) ; tasing you for misspelling mispelling
       grammar           ; tasing grammar mistake every you make

       :term
       vterm             ; the best terminal emulation in Emacs

       :tools
       debugger          ; FIXME stepping through code, to help you add bugs
       direnv
       llm
       ;;docker
       editorconfig      ; let someone else argue about tabs vs spaces
       (eval +overlay)     ; run code, run (also, repls)
       (lookup +devdoc +docsets)              ; navigate your code and its documentation
       (lsp +lsp)                 ; M-x vscode
       magit                ; a git porcelain for Emacs
       pdf               ; pdf enhancements
       ein               ; tame Jupyter notebooks with emacs
       tree-sitter       ; syntax and parsing, sitting in a tree...

       :os
       (:if (featurep :system 'macos) macos)  ; improve compatibility with macOS
       tty               ; improve the terminal Emacs experience

       :lang
       emacs-lisp        ; drown in parentheses
       (go +lsp +tree-sitter)         ; the hipster dialect
       json              ; At least it ain't XML
       ;;lua               ; one-based indices? one-based indices
       (markdown +grip +tree-sitter)          ; writing docs for people to ignore
       (org +roam +dragndrop +noter +pandoc +pomodoro +present +passwords)       ; organize your plain life in plain text
       graphviz          ; diagrams for confusing yourself even more
       (python +lsp +pyright +tree-sitter +uv)                                                ; beautiful is better than ugly
       (rust +lsp +tree-sitter)                                                         ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       (yaml +lsp +tree-sitter)                                                           ; JSON, but readable
       (java +lsp +tree-sitter)

       :app
       ;;calendar
       ;;emms
       everywhere        ; *leave* Emacs!? You must be joking

       :config
       (default +bindings +smartparens))

(setq custom-file (expand-file-name "custom.el" doom-local-dir))
(load custom-file 'no-error 'no-message)
