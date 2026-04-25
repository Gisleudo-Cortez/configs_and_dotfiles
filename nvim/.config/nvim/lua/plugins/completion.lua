-- ============================================================================
-- lua/plugins/completion.lua
-- ----------------------------------------------------------------------------
-- blink.cmp is the modern, performant completion engine for Neovim (2026).
-- It ships LSP, path, buffer, snippets, and signature-help as first-class
-- sources, and uses a Rust fuzzy matcher under the hood.
-- ============================================================================
return {
  -- Snippet engine + snippet library
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = (jit.os:find("Windows") ~= nil and "" or "make install_jsregexp"),
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()  -- loads friendly-snippets
      -- Optional: your own snippets in ~/.config/nvim/snippets
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
    end,
  },

  -- The completion engine itself
  {
    "saghen/blink.cmp",
    dependencies = { "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets" },
    version = "1.*",                    -- prebuilt binary; bump yearly
    event = { "InsertEnter", "CmdlineEnter" },
    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      -- Keymap preset "default" is idiomatic vim:
      --   <C-space>  open menu / show docs
      --   <C-n>/<C-p>  next / prev item
      --   <C-y>      accept
      --   <C-e>      cancel
      --   <Tab>      jump forward in snippet
      --   <S-Tab>    jump backward in snippet
      keymap = {
        preset = "default",
        ["<CR>"]   = { "accept", "fallback" },          -- enter accepts
        ["<Tab>"]  = { "snippet_forward", "fallback" },
        ["<S-Tab>"]= { "snippet_backward", "fallback" },
      },

      appearance = { nerd_font_variant = "mono" },

      completion = {
        trigger = {
          show_on_trigger_character = true,
          show_on_keyword = true,
        },
        accept = { auto_brackets = { enabled = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon", "label", "label_description", gap = 1 },
              { "kind" },
            },
          },
        },
        ghost_text = { enabled = true },
      },

      signature = { enabled = true, window = { border = "rounded" } },

      snippets = { preset = "luasnip" },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          -- Boost LSP items above buffer text
          lsp      = { score_offset = 100, min_keyword_length = 0 },
          snippets = { score_offset = 80 },
          buffer   = { score_offset = 0 },
          path     = { score_offset = 50 },
        },
      },

      -- Fast Rust fuzzy matcher with Lua fallback if the binary is missing
      fuzzy = { implementation = "prefer_rust_with_warning" },

      cmdline = {
        keymap = { preset = "inherit" },
        completion = { menu = { auto_show = true } },
      },
    },
    opts_extend = { "sources.default" },
  },
}
