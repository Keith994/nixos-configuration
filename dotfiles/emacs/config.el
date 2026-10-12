;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(load! "+base.el")      ;; Core settings, user info, performance
(load! "+ui.el")        ;; Theme, fonts, appearance
(load! "+org.el")
(load! "+func.el")      ;; Custom functions
(load! "+use-package.el") ;; Package configurations
(load! "+lsp.el")       ;; LSP and programming configurations
(load! "+keys.el")      ;; Key bindings (should be last)
