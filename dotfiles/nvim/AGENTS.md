# Neovim 配置项目交接文档

## 项目概述

这是一个个人Neovim配置项目，专为大规模项目开发设计，特别支持Golang、Rust和Java语言的开发与调试。项目采用模块化架构，使用Lazy.nvim作为插件管理器，灵感来源于Kickstart.nvim、AstroNvim和LazyVim。

### 核心特性
- 🚀 **高性能**：优化的启动速度和运行时性能
- 🎯 **多语言支持**：Golang、Rust、Java、Python、Lua等
- 🔧 **开发工具集成**：LSP、调试器、测试框架、代码格式化
- 🎨 **现代化UI**：状态栏、文件浏览器、终端集成
- 🔌 **插件化管理**：基于Lazy.nvim的模块化插件系统
- 💻 **VSCode集成**：支持VSCode Neovim扩展

## 项目结构

```
.
├── init.lua                    # 入口文件
├── lazy_setup.lua              # Lazy.nvim插件管理器配置
├── vscode_setup.lua            # VSCode集成配置
├── README.md                   # 项目说明文档
├── generated.lua               # 动态生成的颜色配置
├── stylua.toml                 # Lua代码格式化配置
├── selene.toml                 # Lua静态分析配置
├── lazy-lock.json              # 插件版本锁定文件
├── .neoconf.json               # Neovim配置
├── vim.toml                    # Vim配置
├── .gitignore                  # Git忽略文件
├── asset/                      # 资源文件（截图等）
└── lua/                        # Lua配置模块
    ├── config/                 # 核心配置
    │   ├── init.lua           # 配置初始化
    │   ├── options.lua        # Neovim选项设置
    │   ├── keymaps.lua        # 键盘映射
    │   ├── autocmds.lua       # 自动命令
    │   └── folding.lua        # 代码折叠配置
    ├── plugins/               # 插件配置
    │   ├── editor.lua        # 编辑器增强插件
    │   ├── lsp.lua           # LSP配置
    │   ├── theme.lua         # 主题配置
    │   ├── statusline.lua    # 状态栏配置
    │   ├── formatting.lua    # 代码格式化
    │   ├── linting.lua       # 代码检查
    │   ├── nvim-dap.lua      # 调试器配置
    │   ├── neotest.lua       # 测试框架
    │   ├── coding.lua        # 代码辅助工具
    │   ├── ui.lua           # UI组件
    │   ├── aerial.lua       # 代码大纲
    │   ├── noice.lua        # 通知系统
    │   ├── obsidian.lua     # Obsidian集成
    │   ├── copilot.lua      # GitHub Copilot
    │   ├── blink-cmp.lua    # 代码补全
    │   ├── avante.lua       # 高级功能
    │   ├── hurl.lua         # HTTP测试工具
    │   ├── neogen.lua       # 代码注释生成
    │   ├── mini-surround.lua # 环绕操作
    │   ├── smart-splits.lua  # 智能窗口分割
    │   ├── treesitter.lua    # 语法高亮
    │   ├── none-ls.lua       # Null-ls配置
    │   └── lang/            # 语言特定配置
    │       ├── gopls.lua    # Go语言配置
    │       ├── rust.lua     # Rust语言配置
    │       ├── java.lua     # Java语言配置
    │       ├── python.lua   # Python语言配置
    │       ├── lua_ls.lua   # Lua语言配置
    │       ├── sonar-lint.lua # SonarLint配置
    │       ├── nushell.lua  # Nushell配置
    │       ├── nix.lua      # Nix配置
    │       ├── json.lua     # JSON配置
    │       ├── xml.lua      # XML配置
    │       └── markdown.lua # Markdown配置
    ├── util/                 # 工具函数
    │   ├── init.lua         # 工具函数初始化
    │   ├── icons.lua        # 图标配置
    │   ├── treesitter.lua   # Treesitter工具
    │   ├── switch_to_float.lua # 浮动窗口切换
    │   └── root.lua         # 项目根目录检测
    └── vscode_setup.lua     # VSCode特定配置
```

## 核心配置说明

### 1. 启动流程
1. `init.lua` → 加载`lazy_setup.lua`
2. `lazy_setup.lua` → 初始化Lazy.nvim，加载配置和插件
3. `config/init.lua` → 设置全局工具函数，加载所有配置模块

### 2. 主要配置模块

#### config/options.lua
- 设置Neovim全局选项
- 定义leader键（空格）和localleader键（逗号）
- 配置编辑器行为（自动保存、剪贴板、行号等）
- 设置代码折叠、缩进、颜色方案等

#### config/keymaps.lua
- 定义全局键盘映射
- 窗口管理快捷键（Ctrl+hjkl移动，Ctrl+方向键调整大小）
- 终端集成（Ctrl+/打开终端）
- 代码导航和操作快捷键

#### plugins/lsp.lua
- LSP服务器配置和快捷键
- 代码跳转（gd、gr、gi等）
- 代码操作（重命名、代码操作、CodeLens）
- 调试器集成（F5开始调试，F10单步等）

## 插件生态系统

### 核心插件
1. **UI/外观**
   - `folke/snacks.nvim` - 现代化UI组件（通知、选择器、终端等）
   - `rebelot/heirline.nvim` - 状态栏系统
   - `scottmckendry/cyberdream.nvim` - 主要颜色主题
   - `EdenEast/nightfox.nvim` - 备用颜色主题

2. **代码编辑**
   - `nvim-treesitter/nvim-treesitter` - 语法高亮
   - `neovim/nvim-lspconfig` - LSP配置
   - `hrsh7th/nvim-cmp` - 代码补全
   - `jose-elias-alvarez/null-ls.nvim` - 代码格式化和linting

3. **开发工具**
   - `mfussenegger/nvim-dap` - 调试器
   - `nvim-neotest/neotest` - 测试框架
   - `folke/which-key.nvim` - 快捷键提示
   - `folke/trouble.nvim` - 诊断和问题查看

4. **语言支持**
   - Go: `gopls` + 测试文件切换功能
   - Rust: `rust-analyzer` + `crates.nvim`
   - Java: `jdtls` + 远程调试配置
   - Python: `pyright` + 虚拟环境支持

### 插件管理
- 使用Lazy.nvim进行插件管理
- 插件按功能模块化组织
- 支持延迟加载优化启动速度
- 插件版本通过`lazy-lock.json`锁定

## 开发工作流

### 1. 代码编辑
- **导航**: `gd`跳转到定义，`gr`查看引用，`gi`跳转到实现
- **搜索**: `<leader>sw`搜索当前单词，`<leader>sg`全局搜索
- **重构**: `gR`重命名符号，`ga`代码操作
- **调试**: `F5`开始调试，`F10`单步，`F11`进入函数

### 2. 项目管理
- **文件管理**: `<leader>e`打开文件浏览器，`<leader>o`打开Yazi
- **版本控制**: `<leader>gg`打开LazyGit
- **终端**: `Ctrl+/`打开浮动终端

### 3. 代码质量
- **格式化**: `<localleader>f`格式化当前文件
- **Linting**: 实时语法检查
- **测试**: 集成Neotest运行单元测试

## 语言特定配置

### Go语言
- 支持`gopls` LSP服务器
- 测试文件切换功能（在源文件和测试文件之间切换）
- Go模块感知的项目根目录检测

### Rust语言
- `rust-analyzer` LSP配置
- `crates.nvim`用于Cargo.toml管理
- 集成Neotest测试适配器

### Java语言
- `jdtls` LSP服务器配置
- 远程调试支持（端口5005）
- Maven/Gradle项目支持

## VSCode集成

项目支持VSCode Neovim扩展，提供：
- VSCode特定键盘映射
- 与VSCode命令集成
- 在VSCode中保持一致的编辑体验

## 自定义和扩展

### 添加新插件
1. 在`lua/plugins/`目录下创建新的插件配置文件
2. 在`lazy_setup.lua`的`spec`部分导入新插件
3. 运行`:Lazy sync`安装插件

### 修改配置
- 编辑器选项：修改`lua/config/options.lua`
- 键盘映射：修改`lua/config/keymaps.lua`
- 插件配置：修改对应的插件配置文件

### 添加语言支持
1. 在`lua/plugins/lang/`目录下创建语言配置文件
2. 配置LSP服务器和Treesitter语法
3. 添加语言特定的工具和快捷键

## 故障排除

### 常见问题
1. **插件安装失败**
   - 检查网络连接
   - 运行`:Lazy clean`清除缓存后重试

2. **LSP服务器未启动**
   - 确保语言服务器已安装（如`gopls`、`rust-analyzer`）
   - 检查`:LspInfo`查看服务器状态

3. **主题不生效**
   - 检查`lua/plugins/theme.lua`配置
   - 确保颜色主题插件已正确安装

### 调试命令
- `:Lazy` - 插件管理界面
- `:LspInfo` - LSP服务器信息
- `:TSInstallInfo` - Treesitter语法信息
- `:checkhealth` - Neovim健康检查

## 性能优化

### 启动优化
- 使用Lazy.nvim的延迟加载
- 禁用不必要的内置插件
- 按需加载语言特定配置

### 运行时优化
- 使用Treesitter进行语法高亮
- 异步LSP请求
- 智能缓存机制

## 维护指南

### 更新插件
1. 运行`:Lazy update`更新所有插件
2. 或运行`:Lazy update <plugin-name>`更新特定插件
3. 检查`lazy-lock.json`中的版本变化

### 备份配置
- 配置文件已通过Git版本控制
- 定期提交配置更改
- 重要自定义配置应添加注释说明

### 测试更改
1. 在修改配置前创建分支
2. 使用`:Lazy reload`重新加载配置
3. 测试相关功能确保正常工作

## 未来改进方向

1. **更多语言支持**：添加TypeScript、C++等语言配置
2. **AI集成**：增强Copilot和其他AI工具集成
3. **性能监控**：添加启动时间和运行时性能监控
4. **配置UI**：开发图形化配置界面
5. **文档完善**：添加更多使用示例和教程

---

*最后更新: 2025-12-12*
*维护者: 请参考Git提交历史获取最新维护信息*

