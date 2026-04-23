# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal Neovim configuration targeting Arch Linux + Hyprland + Kitty + Fish, with a heavy data-science/finance focus (Jupyter via molten-nvim, Quarto, SQL via vim-dadbod, inline plots). Built on `lazy.nvim` with Neovim 0.11+ APIs (`vim.lsp.config`, `vim.lsp.enable`, `winborder`, etc.).

## Applying changes

There is no build step. Changes take effect the next time Neovim loads the file. For plugin spec changes, restart Neovim and run `:Lazy sync`. For LSP config changes, `:LspRestart` in an open buffer is enough without a full restart.

Post-install / post-change health checks:
```vim
:checkhealth           " overall health
:Lazy                  " plugin state
:Mason                 " LSP/formatter/linter install state
:ConformInfo           " formatters wired for current buffer
:LspInfo               " LSPs attached to current buffer
```

## Architecture

### Load order (`init.lua`)
1. `vim.g.mapleader = " "` — must be set before lazy loads
2. `require("config.options")` → `require("config.keymaps")` → `require("config.autocmds")`
3. `require("config.lazy")` — bootstraps lazy.nvim and auto-imports all of `lua/plugins/`

### Plugin spec convention
Every file under `lua/plugins/` returns a lazy.nvim spec (table or list-of-tables). lazy.nvim auto-imports the whole directory — just drop a new file in to add plugins. Plugin-specific keymaps live in the spec's `keys =` field, not in `lua/config/keymaps.lua`.

### Keymap namespacing
`<leader>` is `<Space>`. Global, plugin-agnostic keymaps are in `lua/config/keymaps.lua`. The prefixes are:
- `<leader>f*` — find/picker (snacks)
- `<leader>c*` — code/LSP
- `<leader>g*` — git
- `<leader>d*` / `<F*>` — debug (DAP)
- `<leader>x*` — diagnostics/trouble
- `<leader>u*` — UI toggles
- `<leader>b*` — buffers
- `<leader>j*` — Jupyter/molten
- `<leader>q*` — Quarto (`.qmd` files only)
- `<leader>D*` — databases (vim-dadbod)
- `<leader>s*` — search/symbols

### LSP pattern (Nvim 0.11+)
`lua/plugins/lsp.lua` uses `vim.lsp.config('server', { ... })` for per-server settings and relies on `mason-lspconfig` with `automatic_enable = true` to call `vim.lsp.enable()`. Per-buffer keymaps are set in a single `LspAttach` autocmd at the bottom of that file. Do **not** use the `on_attach` callback pattern for keymaps.

### Format-on-save
`conform.nvim` (`lua/plugins/formatting.lua`) runs on `BufWritePre`. Toggle per-buffer with `<leader>uf`. Disable globally with `vim.g.disable_autoformat = true` in `init.lua`. Check active formatters with `:ConformInfo`.

### Python / Jupyter setup
molten-nvim requires a dedicated Neovim Python venv at `~/.virtualenvs/neovim/`. Both `lua/config/options.lua` and `lua/plugins/datascience.lua` set `vim.g.python3_host_prog` to that venv's Python if it exists. After any plugin change that touches the Python host, run `:UpdateRemotePlugins` and restart.

`image.nvim` and molten's image output are gated on `$TERM == xterm-kitty` or `$KITTY_WINDOW_ID` — they silently disable themselves in other terminals.

## Adding things

- **New plugin**: add a file to `lua/plugins/` returning a lazy spec.
- **New LSP server**: add mason name to `ensure_installed` in `lua/plugins/lsp.lua` (mason-lspconfig table), add per-server config with `vim.lsp.config(...)` in the same file.
- **New formatter**: add to `formatters_by_ft` in `lua/plugins/formatting.lua` and to `ensure_installed` in the mason-tool-installer spec in `lua/plugins/lsp.lua`.
- **New filetype/environment detection**: add to `lua/plugins/environment.lua`.
- **Private DB connections**: create `lua/local.lua` (gitignored), set `vim.g.dbs = { ... }`, and `require('local')` from `init.lua`.

## Key files

| File | Purpose |
|------|---------|
| `init.lua` | Entry point, load order, leader key |
| `lua/config/options.lua` | All `vim.opt.*` settings + diagnostic config |
| `lua/config/keymaps.lua` | Global keymaps (non-plugin) |
| `lua/config/autocmds.lua` | All autocommands |
| `lua/config/lazy.lua` | lazy.nvim bootstrap + `:Lazy` keymap |
| `lua/plugins/lsp.lua` | mason + mason-lspconfig + all `vim.lsp.config()` calls + LspAttach keymaps |
| `lua/plugins/datascience.lua` | molten, image.nvim, jupytext, quarto, otter, NotebookNavigator, csvview |
| `lua/plugins/formatting.lua` | conform.nvim format-on-save |
| `lua/plugins/environment.lua` | Hyprland/Fish/Kitty filetype detection + kitty-scrollback |
