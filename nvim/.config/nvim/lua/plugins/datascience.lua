-- ============================================================================
-- lua/plugins/datascience.lua
-- ----------------------------------------------------------------------------
-- A Jupyter-like experience inside Neovim, built on:
--
--   molten-nvim       — async code execution against a jupyter kernel,
--                       renders output + PNG/LaTeX inline
--   image.nvim        — ANSI/Kitty-graphics image display (works great in Kitty!)
--   jupytext.nvim     — open .ipynb files by round-tripping through .py / .md
--   quarto-nvim       — .qmd literate programming + dispatch to molten
--   otter.nvim        — virtual LSP for code chunks inside markdown / .qmd
--   NotebookNavigator — `# %%` cell navigation for plain .py files
--   csvview.nvim      — show CSV/TSV files as aligned columns
--   render-markdown   — render markdown in-buffer (good for quarto previews)
--
-- ── Python dependencies (install once) ──
-- Molten talks to jupyter.  Create a dedicated nvim venv so molten's python
-- deps don't pollute your project envs:
--
--   mkdir -p ~/.virtualenvs && cd ~/.virtualenvs
--   python -m venv neovim
--   source neovim/bin/activate
--   pip install pynvim jupyter_client ipykernel jupytext nbformat \
--               cairosvg plotly kaleido pillow pyperclip
--   python -m ipykernel install --user --name nvim
--
-- Then in nvim:  :UpdateRemotePlugins
-- and point g:python3_host_prog at that venv's python (set in init.lua below).
--
-- For each project, also `pip install ipykernel jupytext` inside the project
-- venv and register its kernel:
--   python -m ipykernel install --user --name <project_name>
-- ============================================================================

-- Detect Kitty so image.nvim uses the correct backend automatically.
local is_kitty = vim.env.TERM == "xterm-kitty" or vim.env.KITTY_WINDOW_ID ~= nil

-- Point Neovim at the dedicated nvim venv (adjust path if you chose another).
local nvim_python = vim.fn.expand("~/.virtualenvs/neovim/bin/python")
if vim.fn.filereadable(nvim_python) == 1 then
  vim.g.python3_host_prog = nvim_python
end

return {
  -- ── image.nvim ─────────────────────────────────────────────────────────
  {
    "3rd/image.nvim",
    build = false, -- no post-install step
    event = "VeryLazy",
    cond = is_kitty, -- only load under Kitty
    opts = {
      backend = "kitty", -- best backend for the Kitty terminal
      processor = "magick_cli", -- requires imagemagick on PATH
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki", "quarto" },
        },
        neorg = { enabled = false },
      },
      max_width = 100,
      max_height = 20,
      max_width_window_percentage = nil,
      max_height_window_percentage = 40,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_picker_list" },
    },
  },

  -- ── molten-nvim (Jupyter) ──────────────────────────────────────────────
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    cmd = {
      "MoltenInit",
      "MoltenEvaluateLine",
      "MoltenEvaluateVisual",
      "MoltenEvaluateOperator",
      "MoltenEvaluateArgument",
      "MoltenReevaluateCell",
      "MoltenDelete",
      "MoltenShowOutput",
      "MoltenHideOutput",
      "MoltenRestart",
      "MoltenInterrupt",
      "MoltenInfo",
      "MoltenImagePopup",
      "MoltenExportOutput",
      "MoltenImportOutput",
    },
    ft = { "python", "quarto", "markdown" },
    init = function()
      -- image provider — fall back gracefully if not in Kitty
      vim.g.molten_image_provider = is_kitty and "image.nvim" or "none"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false -- manual — quieter
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true -- show output as virtual text next to cell
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_use_border_highlights = true
    end,
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<CR>", desc = "Initialize molten" },
      { "<leader>je", ":MoltenEvaluateOperator<CR>", desc = "Evaluate operator" },
      { "<leader>jl", ":MoltenEvaluateLine<CR>", desc = "Evaluate line" },
      { "<leader>jr", ":MoltenReevaluateCell<CR>", desc = "Re-eval cell" },
      {
        "<leader>jv",
        ":<C-u>MoltenEvaluateVisual<CR>gv",
        desc = "Evaluate selection",
        mode = "v",
      },
      { "<leader>jd", ":MoltenDelete<CR>", desc = "Delete cell" },
      { "<leader>jo", ":MoltenShowOutput<CR>", desc = "Show output" },
      { "<leader>jh", ":MoltenHideOutput<CR>", desc = "Hide output" },
      { "<leader>js", ":noautocmd MoltenEnterOutput<CR>", desc = "Enter output scroll" },
      { "<leader>jI", ":MoltenInterrupt<CR>", desc = "Interrupt kernel" },
      { "<leader>jR", ":MoltenRestart!<CR>", desc = "Restart kernel" },
    },
  },

  -- ── jupytext (open .ipynb transparently via round-trip) ────────────────
  {
    "GCBallesteros/jupytext.nvim",
    event = "BufAdd *.ipynb",
    opts = {
      -- Neovim sees .ipynb as these formats; round-trip transparently.
      style = "markdown", -- or "hydrogen" for `# %%` cell markers in .py
      output_extension = "md",
      force_ft = "markdown",
    },
    lazy = false, -- needed BEFORE the buffer is read
    priority = 100,
  },

  -- ── quarto (.qmd documents with executable code cells) ────────────────
  {
    "quarto-dev/quarto-nvim",
    ft = { "quarto" },
    dependencies = { "jmbuhr/otter.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      lspFeatures = {
        languages = { "python", "r", "julia", "bash", "html", "lua" },
        chunks = "all",
        diagnostics = { enabled = true, triggers = { "BufWritePost" } },
        completion = { enabled = true },
      },
      codeRunner = {
        enabled = true,
        default_method = "molten",
        ft_runners = {},
        never_run = { "yaml" },
      },
    },
    keys = {
      {
        "<leader>qp",
        function()
          require("quarto").quartoPreview()
        end,
        desc = "Quarto preview",
      },
      {
        "<leader>qq",
        function()
          require("quarto").quartoClosePreview()
        end,
        desc = "Quarto close preview",
      },
      {
        "<leader>qh",
        function()
          require("quarto.runner").run_cell()
        end,
        desc = "Run cell",
      },
      {
        "<leader>qr",
        function()
          require("quarto.runner").run_above()
        end,
        desc = "Run above",
      },
      {
        "<leader>qR",
        function()
          require("quarto.runner").run_all()
        end,
        desc = "Run all",
      },
      {
        "<leader>ql",
        function()
          require("quarto.runner").run_line()
        end,
        desc = "Run line",
      },
      {
        "<leader>qv",
        function()
          require("quarto.runner").run_range()
        end,
        desc = "Run range",
        mode = "v",
      },
      {
        "<leader>qa",
        function()
          require("quarto.runner").run_all(true)
        end,
        desc = "Run all cells (of all languages)",
      },
    },
  },

  -- ── otter (LSP inside code cells of markdown / quarto) ────────────────
  {
    "jmbuhr/otter.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },

  -- ── NotebookNavigator (plain .py cell navigation via `# %%`) ──────────
  {
    "GCBallesteros/NotebookNavigator.nvim",
    keys = {
      {
        "]c",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next cell",
      },
      {
        "[c",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Prev cell",
      },
      {
        "<leader>jx",
        function()
          require("notebook-navigator").run_cell()
        end,
        desc = "Run cell",
      },
      {
        "<leader>jn",
        function()
          require("notebook-navigator").run_and_move()
        end,
        desc = "Run cell + advance",
      },
    },
    dependencies = {
      "echasnovski/mini.comment",
    },
    event = "VeryLazy",
    config = function()
      require("notebook-navigator").setup({ activate_hydra_keys = "<leader>jk" })
    end,
  },

  -- ── csvview (aligned tabular view for CSV / TSV) ──────────────────────
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv", "csv_semicolon", "csv_pipe", "rfc_csv", "rfc_semicolon" },
    opts = {
      parser = { comments = { "#", "//" } },
      view = {
        display_mode = "border",
        header_lnum = 1,
        sticky_header = { enabled = true, separator = "─" },
      },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    keys = {
      { "<leader>uc", "<cmd>CsvViewToggle<CR>", desc = "Toggle CSV column view" },
    },
  },

  -- ── render-markdown (pretty in-buffer markdown, great with quarto) ───
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
    ft = { "markdown", "quarto", "Avante" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = { sign = false, icons = {} },
      checkbox = { enabled = true },
    },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown render" },
    },
  },
}
