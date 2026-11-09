return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    opts = {
      -- 走 Ollama 的 OpenAI 兼容 /v1/completions（支持 prompt + suffix 的 FIM），
      -- 比 chat 模板更适合内联补全。
      provider = "openai_fim_compatible",
      n_completions = 2,
      -- 单位是字符：2048 约等于前后共 512 token，对 3B 的 prefill 压力很小。
      context_window = 2048,
      context_ratio = 0.75,
      -- 本地模型延迟低，默认的 1000ms throttle 太保守。
      throttle = 150,
      debounce = 200,
      -- 首次请求可能赶上 Ollama 冷加载模型，留宽一点。
      request_timeout = 20,
      notify = "warn",
      -- 作为 blink source 自动请求，不需要 virtualtext，也不需要按 <A-y>。
      blink = {
        enable_auto_complete = true,
      },
      provider_options = {
        openai_fim_compatible = {
          -- Ollama 不校验 key，Minuet 又必须给一个环境变量名，借 TERM 避免空值报错。
          api_key = "TERM",
          name = "Ollama",
          end_point = "http://127.0.0.1:11434/v1/completions",
          -- 换 7B 只改这一行；纯 FIM 也可以换成 qwen2.5-coder:3b-base。
          model = "qwen2.5-coder:3b",
          optional = {
            max_tokens = 48,
            temperature = 0.1,
            top_p = 0.9,
          },
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "milanglacier/minuet-ai.nvim" },
    opts = function(_, opts)
      local minuet = require("minuet")

      -- 手动触发作为兜底；正常输入时由 blink 自动请求，不需要按。
      opts.keymap = opts.keymap or {}
      opts.keymap["<A-y>"] = minuet.make_blink_map()

      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        -- 与 request_timeout 对齐，避免 blink 先超时丢掉结果。
        timeout_ms = 10000,
        -- 比 LSP 候选更靠前，和之前 copilot source 一样优先展示。
        score_offset = 100,
      }

      opts.sources.default = opts.sources.default or {}
      if not vim.tbl_contains(opts.sources.default, "minuet") then
        table.insert(opts.sources.default, "minuet")
      end
      return opts
    end,
  },
}
