# Neovim Config — Arch + Hyprland + Kitty + Fish, finance / data science

A modern Neovim configuration built on `lazy.nvim` with the 2026 best-in-class
stack (`blink.cmp`, `conform.nvim`, `nvim-lint`, `snacks.nvim`, native
`vim.lsp.config`) — extended for:

- **Arch + Hyprland + Kitty + Fish** (filetype detection, LSPs, inline images)
- **Data-science / finance workflow**: Jupyter-in-Neovim via `molten-nvim`,
  Quarto, CSV column view, inline plots (thanks to Kitty's graphics protocol),
  and `vim-dadbod` as a SQL IDE for DuckDB / Postgres / Snowflake / SQLite.

---

## Requirements

Arch packages (`sudo pacman -S ...`):

```text
neovim git ripgrep fd lazygit kitty fish
imagemagick                  # for image.nvim inline plots
qt6-declarative              # qmlls language server
tectonic zathura             # latex build + pdf viewer (adjust to taste)
duckdb postgresql-libs       # SQL backends for vim-dadbod
```

From AUR (via `yay`/`paru`):

```text
tree-sitter-cli    # for nvim-treesitter to compile on first run
```

Python side (a dedicated venv for Neovim itself):

```fish
mkdir -p ~/.virtualenvs; and cd ~/.virtualenvs
python -m venv neovim
source neovim/bin/activate.fish
pip install pynvim jupyter_client ipykernel jupytext nbformat \
            cairosvg plotly kaleido pillow pyperclip
python -m ipykernel install --user --name nvim
```

Per-project Jupyter kernel (repeat per project):

```fish
source venv/bin/activate.fish
pip install ipykernel jupytext
python -m ipykernel install --user --name project-name
```

Optional: a Nerd Font (`ttf-jetbrains-mono-nerd` is a good default) configured
in kitty for icons.

---

## Install

```bash
mv ~/.config/nvim        ~/.config/nvim.bak         2>/dev/null
mv ~/.local/share/nvim   ~/.local/share/nvim.bak    2>/dev/null
mv ~/.local/state/nvim   ~/.local/state/nvim.bak    2>/dev/null
mv ~/.cache/nvim         ~/.cache/nvim.bak          2>/dev/null

tar xzf nvim-config.tar.gz -C ~/.config/
# ~/.config/nvim now exists

nvim
# lazy.nvim bootstraps → plugins install → mason installs LSPs/formatters/DAPs
# on first launch of a Python file, run :UpdateRemotePlugins for molten
```

Post-install checklist:

```vim
:checkhealth             " green across the board?
:Mason                   " confirm every LSP is installed
:checkhealth molten      " if you plan to use Jupyter
:UpdateRemotePlugins     " molten python host
```

---

## Layout

```
nvim/
├── init.lua                  # entry point; leader = <Space>
├── lua/
│   ├── config/
│   │   ├── options.lua       # editor options (numbers, tabs, folds…)
│   │   ├── keymaps.lua       # global keymaps (incl. <leader>w → save)
│   │   ├── autocmds.lua      # autocommands
│   │   └── lazy.lua          # plugin-manager bootstrap
│   └── plugins/
│       ├── colorscheme.lua   # tokyonight (+ alternates)
│       ├── snacks.lua        # picker, explorer, lazygit, dashboard …
│       ├── treesitter.lua    # syntax/indent/folds/textobjects (40+ parsers)
│       ├── lsp.lua           # mason + nvim-lspconfig (20+ servers)
│       ├── completion.lua    # blink.cmp + LuaSnip + friendly-snippets
│       ├── formatting.lua    # conform.nvim (format-on-save)
│       ├── linting.lua       # nvim-lint (async external linters)
│       ├── git.lua           # gitsigns
│       ├── ui.lua            # lualine / which-key / noice / icons
│       ├── editor.lua        # autopairs, surround, flash, trouble, yanky …
│       ├── dap.lua           # nvim-dap + ui + adapters
│       ├── datascience.lua   # molten + jupytext + quarto + image + csvview …
│       ├── database.lua      # vim-dadbod + ui + completion
│       └── environment.lua   # Hyprland/Fish/Kitty filetypes; kitty-scrollback
└── README.md
```

Adding another plugin: drop a file into `lua/plugins/` returning a lazy
spec (table or list-of-tables). `lazy.nvim` auto-imports everything.

---

## Languages

### LSPs auto-installed

| Group        | Servers (mason names map to these automatically)                                |
|--------------|--------------------------------------------------------------------------------|
| Data / DS    | `basedpyright`, `ruff`, `r_language_server`, `texlab`, `sqlls`                  |
| Systems      | `rust_analyzer`, `gopls`, `clangd`, `zls`                                        |
| Web / front  | `ts_ls`, `eslint`, `html`, `cssls`, `tailwindcss`                                |
| JVM / other  | `jdtls`, `kotlin_language_server`, `elixirls`, `intelephense`                    |
| Config       | `jsonls`, `yamlls` (with schemastore), `taplo`, `marksman`, `bashls`             |
| Docker       | `dockerls`, `docker_compose_language_service`                                    |
| Arch stack   | `hyprls`, `qmlls`, `fish_lsp`, `nil_ls`                                          |
| Lua (config) | `lua_ls`                                                                          |

Want more? `:MasonInstall <server>` at runtime, or append the name to
`ensure_installed` in `lua/plugins/lsp.lua`.

### Formatters (`conform.nvim`, on save)

| Group        | Chain                                                 |
|--------------|-------------------------------------------------------|
| Python       | `ruff_organize_imports` → `ruff_format`               |
| R            | `styler`                                              |
| SQL          | `sqlfluff`                                            |
| LaTeX        | `latexindent`                                         |
| Web/JSON/YAML/MD | `prettierd` (→ `prettier` fallback)              |
| QML          | `qmlformat`                                           |
| Rust / Go / C-C++ / Zig / CUDA | `rustfmt` / `goimports`+`gofumpt` / `clang_format` / `zigfmt` |
| Java / Kotlin / Scala | `google-java-format` / `ktlint` / `scalafmt` |
| Ruby / PHP / Elixir / Haskell | `rubocop` / `php_cs_fixer` / `mix format` / `fourmolu` |
| Shell        | `shfmt` (bash/sh/zsh), `fish_indent` (fish)           |
| TOML / Nix   | `taplo` / `nixfmt`                                    |
| Lua          | `stylua`                                              |

### Linters (`nvim-lint`)

`shellcheck`, `markdownlint`, `chktex`, `hadolint`, `yamllint`, `tflint`,
`sqlfluff` — LSPs handle the rest.

---

## Data science / finance features

### Jupyter inside Neovim (molten + jupytext + quarto + image.nvim)

- Open any `.ipynb` directly — `jupytext.nvim` intercepts and presents it as
  markdown. Save → round-trips back to `.ipynb`.
- For plain `.py`, use `# %%` cell markers and `NotebookNavigator`
  (`]c` / `[c` to move, `<leader>jx` to run).
- `.qmd` (Quarto) files get full LSP *inside* code cells via `otter.nvim`.
- Output rendering: stdout as virtual text, matplotlib / PIL / plotly figures
  inline via Kitty's graphics protocol (automatically detected — no config).

### Jupyter keymaps (`<leader>j*`)

| Key          | Action                                   |
|--------------|------------------------------------------|
| `<leader>ji` | Initialize molten (choose kernel)        |
| `<leader>jl` | Evaluate line                            |
| `<leader>je` | Evaluate operator (e.g. `<leader>jeip`)  |
| `<leader>jv` | Evaluate visual selection                |
| `<leader>jr` | Re-evaluate current cell                 |
| `<leader>jd` | Delete cell                              |
| `<leader>jo` / `<leader>jh` | Show / hide output         |
| `<leader>js` | Enter output window (for scrolling)      |
| `<leader>jI` | Interrupt kernel                         |
| `<leader>jR` | Restart kernel                           |
| `<leader>jx` / `<leader>jn` | Run cell / run + advance (plain `.py`) |
| `]c` / `[c`  | Next / prev cell                         |

### Quarto keymaps (`<leader>q*`) — active in `.qmd` files

| Key          | Action                                   |
|--------------|------------------------------------------|
| `<leader>qp` / `<leader>qq` | Preview / close preview   |
| `<leader>ql` | Run line                                 |
| `<leader>qh` | Run cell                                 |
| `<leader>qr` / `<leader>qR` / `<leader>qa` | Run above / all / all-langs |
| `<leader>qv` | Run range (visual)                       |

### CSV / TSV column view

Open any CSV/TSV → automatically aligned in columns.

| Key            | Action                            |
|----------------|-----------------------------------|
| `<leader>uc`   | Toggle column view                |
| `<Tab>` / `<S-Tab>` | Next / prev field              |
| `<Enter>` / `<S-Enter>` | Next / prev row            |
| `if` / `af`    | Inner / around field (textobject) |

### SQL / databases (`<leader>D*`) — vim-dadbod

| Key            | Action                            |
|----------------|-----------------------------------|
| `<leader>Du`   | Toggle DB UI                      |
| `<leader>Da`   | Add new DB connection             |
| `<leader>Df`   | Find DB buffer                    |
| `<leader>S` (in SQL buffer) | Run selection / buffer |

Example `lua/local.lua` (gitignored) to register your daily connections:

```lua
-- ~/.config/nvim/lua/local.lua   (add `require('local')` in init.lua if you keep one)
vim.g.dbs = {
  prices    = "duckdb:/data/prices.duckdb",
  warehouse = "postgres://user:pw@localhost:5432/warehouse",
  research  = "sqlite:" .. vim.fn.expand("~/research.sqlite"),
  -- snowflake = "snowflake://...@account/db/schema?warehouse=WH",
}
```

DuckDB is the sweet spot for finance — it reads Parquet/CSV directly, so you
can point `:DB duckdb::memory: ← SELECT * FROM 'returns.parquet' LIMIT 20;`
at any file without loading it into a DB first.

---

## Arch / Hyprland / Kitty / Fish integration

- **Filetype detection** (`environment.lua`) for
  `hyprland.conf`, `hyprpaper.conf`, `hypridle.conf`, `hyprlock.conf`,
  anything under `~/.config/hypr/`, `kitty.conf`, fish config files,
  `waybar/config*` (as jsonc), `rofi/*.rasi`, `PKGBUILD`.
- **LSPs**: `hyprls` (Hyprland), `qmlls` (QML), `fish_lsp` (Fish), `nil_ls` (Nix).
- **kitty-scrollback.nvim** (optional) lets you edit Kitty's scrollback buffer
  in Neovim. To enable it, add to `~/.config/kitty/kitty.conf`:

  ```conf
  # kitty-scrollback.nvim Kitten alias
  action_alias kitty_scrollback_nvim kitten ${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py

  # Browse scrollback in nvim
  map kitty_mod+h kitty_scrollback_nvim
  # Browse the output of the last command
  map kitty_mod+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output
  ```

  Then `:KittyScrollbackGenerateKittens` in nvim.

- **Inline images** (image.nvim) only activates when `$TERM == xterm-kitty`
  or `$KITTY_WINDOW_ID` is set — no config needed.

---

## Keymaps (full reference)

### File / buffer

| Key           | Action                               |
|---------------|--------------------------------------|
| `<leader>w`   | **Save**                             |
| `<leader>W`   | Save all                             |
| `<leader>wq`  | Save and quit *(ported)*             |
| `<leader>q` / `<leader>Q` | Quit / quit all          |
| `<C-s>`       | Save (also works in insert)          |
| `<S-h>` / `<S-l>` | Prev / next buffer               |
| `<leader>bd` / `<leader>bo` | Delete buf / delete others |
| ``<leader>` `` | Switch to last buffer               |

### Find / search (snacks.picker)

| Key               | Action                  |
|-------------------|-------------------------|
| `<leader><space>` | Smart find              |
| `<leader>ff`      | Find files              |
| `<leader>fg`      | Live grep               |
| `<leader>fw`      | Grep word under cursor  |
| `<leader>fb`      | Buffers                 |
| `<leader>fr`      | Recent files            |
| `<leader>fk`      | Keymaps                 |
| `<leader>fh`      | Help tags               |
| `<leader>fc`      | Commands                |
| `<leader>:`       | Command history         |

### LSP / code

| Key            | Action                              |
|----------------|-------------------------------------|
| `gd` / `gD`    | Goto definition / declaration       |
| `gr`           | References                          |
| `gI` / `gy`    | Implementations / type definitions  |
| `K`            | Hover                               |
| `<C-k>`        | Signature help                      |
| `<leader>ca`   | Code action                         |
| `<leader>cr` / `<leader>rn` | Rename symbol *(rn is a ported alias)* |
| `<leader>cf` / `<leader>fm` | Format buffer / selection *(fm is a ported alias)* |
| `<leader>cL`   | Lint buffer                         |
| `<leader>cl`   | LSP info                            |
| `<leader>cm`   | Mason                               |
| `<leader>cR`   | Rename file (LSP-aware)             |
| `<leader>ss` / `<leader>sS` | Doc / workspace symbols |
| `<leader>uh`   | Toggle inlay hints                  |

### Diagnostics

| Key            | Action                              |
|----------------|-------------------------------------|
| `]d` / `[d`    | Next / prev diagnostic              |
| `]e` / `[e`    | Next / prev error                   |
| `<leader>xd` / `<leader>de` | Line diagnostic float *(de is a ported alias)* |
| `<leader>xx`   | Workspace diagnostics picker        |
| `<leader>xX`   | Trouble: diagnostics                |

### Git

| Key            | Action                              |
|----------------|-------------------------------------|
| `<leader>gg`   | Lazygit                             |
| `<leader>gl`   | Lazygit log                         |
| `<leader>gs` / `<leader>gb` / `<leader>gd` | Status / branches / diff |
| `<leader>gB`   | Open in browser                     |
| `]h` / `[h`    | Next / prev hunk                    |
| `<leader>ghs` / `ghr` / `ghp` | Stage / reset / preview hunk |
| `<leader>ghb`  | Blame line                          |
| `<leader>gt`   | Toggle inline blame                 |

### Debug (DAP)

| Key            | Action                              |
|----------------|-------------------------------------|
| `<leader>db` / `dB` | Toggle / conditional breakpoint |
| `<leader>dc` / `di` / `do` / `dO` | Continue / step-in / over / out |
| `<F5>` / `<F6>` / `<F9>` / `<F10>` / `<F11>` / `<F12>` | Continue / Stop / Toggle BP / Step over / into / out *(F-key aliases from old config)* |
| `<leader>du` / `dr` / `dt` | DAP UI / REPL / terminate |
| `<leader>dPt` / `dPc` (py) | Debug test method / class |

### Data science / Jupyter / Quarto / DB

See the **Data science / finance features** section above.

### Misc / toggles

| Key            | Action                              |
|----------------|-------------------------------------|
| `<leader>e`    | File explorer (snacks)              |
| `<leader>.`    | Scratch buffer                      |
| `<leader>z`    | Zen mode                            |
| `<leader>l`    | Lazy plugin manager                 |
| `<leader>uw`   | Toggle word-wrap                    |
| `<leader>uf`   | Toggle format-on-save (buffer)      |
| `<leader>uc`   | Toggle CSV column view              |
| `<leader>um`   | Toggle markdown render              |
| `<leader>ut`   | Toggle treesitter context           |
| `<leader>us`   | Toggle spell                        |
| `<leader>ud`   | Toggle diagnostics                  |
| `<C-/>`        | Toggle floating terminal            |
| `s`            | Flash jump                          |
| `<leader>?`    | Which-key: buffer keymaps           |

---

## Tweaking

- **Colorscheme** → `lua/plugins/colorscheme.lua` (swap `tokyonight` for
  `catppuccin`, `kanagawa`, `rose-pine`).
- **Add a language** → append the server name to `ensure_installed` in
  `lua/plugins/lsp.lua`, parser name to `lua/plugins/treesitter.lua`,
  formatter to `lua/plugins/formatting.lua`.
- **Disable format-on-save globally** → `vim.g.disable_autoformat = true` in
  `init.lua`, or per-buffer with `<leader>uf`.
- **Private DB connections** → create `lua/local.lua` (gitignore it!),
  put `vim.g.dbs = { … }` there, then `require('local')` at the top of
  `init.lua`.

---

## Troubleshooting

| Symptom                                  | Fix                                                         |
|------------------------------------------|-------------------------------------------------------------|
| `:Molten` commands silent                | Run `:UpdateRemotePlugins`, restart nvim.                   |
| Images not showing                       | `checkhealth image`; confirm `imagemagick` on `$PATH` and `$TERM=xterm-kitty`. |
| `qmlls` not attaching                    | `pacman -S qt6-declarative`; `:LspInfo` to confirm cmd path. |
| Ruff + basedpyright show duplicate diags | Expected — each covers different checks.                    |
| `fish-lsp` not found                     | `:MasonInstall fish-lsp` (mason name has a hyphen).          |
| Treesitter parser fails to compile       | Install `tree-sitter-cli` + a C compiler; `:TSUpdate`.       |
| Slow startup                             | `:Lazy profile` to find the offender; move to `event=`/`ft=`.|

`:checkhealth` for the full diagnosis, and `:Lazy` to manage plugin state.
