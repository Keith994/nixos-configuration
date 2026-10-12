# AGENTS.md - Doom Emacs Configuration

This is a Doom Emacs configuration (~/.doom.d). The configuration is written in Emacs Lisp (.el files).

## Project Structure

```
~/.doom.d/
├── init.el          # Doom module declarations
├── config.el        # Loads all modules in sequence
├── packages.el       # Package definitions and disabled packages
├── custom.el        # Auto-generated customizations (do not edit manually)
├── +base.el         # Core settings, encoding, performance
├── +ui.el           # Theme, fonts, modeline configuration
├── +func.el         # Custom functions (prefixed with my/)
├── +use-package.el  # use-package configurations
├── +lsp.el          # LSP and programming language settings
└── +keys.el         # Keybindings (loaded last)
```

## Commands

### Syncing and Building
```bash
doom sync        # Sync packages and config
doom doctor      # Check for issues
doom build       # Compile config
doom refresh     # Refresh everything
```

### Running Tests
This is an Emacs configuration, not a software project with tests. There is no test framework.

### Linting
```bash
doom lint        # Run Doom's built-in linter
emacs --batch --eval "(progn (load \"~/.emacs.d/init.el\") (byte-compile-file \"~/.doom.d/config.el\"))"  # Byte-compile check
```

## Code Style Guidelines

### File Organization
- Use `;;; filename.el -*- lexical-binding: t; -*-` header on all files
- Follow Doom's module convention: `+module-name.el` for feature modules
- Load order in `config.el`: base → ui → func → use-package → lsp → keys

### Emacs Lisp Conventions
- Always enable `lexical-binding` at the file level
- Use `;;` for comments, `;;;` for section headers
- Use Chinese/English comments as appropriate (config uses Chinese for user-facing docs)
- Prefer `cl-` prefix for Common Lisp compatibility functions
- Use `pcase` for pattern matching when appropriate

### Naming Conventions
- Custom functions: prefix with `my/` (e.g., `my/function-name`)
- Module-private functions: prefix with `+` (e.g., `+format/region-or-buffer`)
- Variables: use `defvar` or `defcustom` for configuration
- Use kebab-case for function/variable names
- Suffix predicates with `-p` (e.g., `my/valid-p`)

### Keybindings
- Use Doom's `map!` macro for keybindings
- Define leader keys with `map! :prefix`
- Use descriptive `:desc` for documentation
- Use `(define-key global-map (kbd "...") ...)` for global keys
- Example:
  ```elisp
  (map! :map emacs-lisp-mode-map "C-c C-f" #'some-formatter)
  ```

### Imports and Packages
- Use `use!` for conditional module loading (Doom-specific)
- Use `(load! "+module.el")` to load local modules
- Use `(require 'package)` for external packages
- Package definitions go in `packages.el`
- Use `(package! name :recipe ...)` for external packages with custom recipes
- Use `(disable-packages! package1 package2 ...)` to disable unwanted packages

### Autoload
- Use `;;;###autoload` before functions that should be autoloaded
- This generates auto-autoloads.el for faster loading
- Only autoload frequently-used interactive commands

### Formatting
- Use Doom's `format!` and `set-formatter!` for code formatters
- Config uses `(set-formatter! 'name command :modes '(major-mode))`
- Default fill-column is 120 characters
- Set with `(setq-default fill-column 120)`

### Error Handling
- Use `when` for conditional execution without else branch
- Use `if` for explicit else branches
- Use `condition-case` for complex error handling
- Use `user-error` for user-facing errors
- Use `ignore-errors` for non-critical error suppression

### Code Patterns
- Use `with-eval-after-load` for lazy loading (after package loads)
- Use `after!` macro for module dependencies (Doom-specific)
- Example:
  ```elisp
  (with-eval-after-load 'gcmh
    (setq gcmh-idle-delay 60))
  ```
- Use `add-hook` for mode hooks
- Use `advice-add` for advice functions

### Variables and Configuration
- Use `defvar` for internal variables
- Use `defcustom` for user-configurable variables
- Use `setq` for setting variables
- Use `custom-set-variables` in early-init or with `customize-set-variable`
- Prefix custom faces with `custom/` if needed

### Performance
- Use `read-process-output-max` for LSP performance (set high: (* 16 1024 1024))
- Use `gc-cons-threshold` carefully in `early-init.el`
- Defer non-essential features with `defer!` or `after!`
- Use `with-eval-after-load` to delay expensive configurations

### UI/Theme Configuration
- Set theme with `(setq doom-theme 'doom-theme-name)`
- Set font with `(setq doom-font "Font Name")`
- Define custom faces with `(defface face-name ...)`
- Use `set-popup-rules!` for popup window behavior

### Conditional Configuration
- Use `(when (eq system-type 'gnu/linux) ...)` for OS-specific config
- Use `(when (getenv "WAYLAND_DISPLAY") ...)` for display server detection
- Use `(when (featurep 'module-name) ...)` for feature detection

## Important Notes

1. **Missing Function**: The function `#'+format/region-or-buffer` referenced in +keys.el (lines 174, 226, 232) does NOT exist - it needs to be defined or replaced with an existing formatter like `lsp-format-buffer` or `format-all-buffer`.

2. **Config Uses**:
   - vertico + corfu for completion
   - LSP for language servers (basedpyright, gopls, rust-analyzer, ts-ls)
   - tree-sitter for improved syntax parsing
   - gptel for AI interactions (uses deepseek-chat by default)
   - catppuccin theme (mocha flavor)

3. **Language Servers**:
   - Python: basedpyright (configured in +base.el)
   - Go: gopls
   - Rust: rust-analyzer
   - YAML: yaml-language-server
   - JSON: json-lsp

4. **Key Custom Functions**:
   - Location: `+func.el`
   - Prefix: `my/` (e.g., `my/new-scratch-buffer`, `my/switch-to-last-open-buffer`)

5. **Keybindings**: Located in `+keys.el` (loaded last)
