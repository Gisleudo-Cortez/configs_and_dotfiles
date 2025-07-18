-- Completion and snippet setup (nvim-cmp + LuaSnip)
return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()
			cmp.setup({
				snippet = {
					expand = function(args) luasnip.lsp_expand(args.body) end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-k>"]     = cmp.mapping.select_prev_item(),
					["<C-j>"]     = cmp.mapping.select_next_item(),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"]     = cmp.mapping.abort(),
					["<CR>"]      = cmp.mapping.confirm({ select = true }),
					["<Tab>"]     = cmp.mapping(function(fallback)
						if luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"]   = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp_signature_help"},
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer" },
				}),
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				experimental = { ghost_text = true },
			})
		end,
	},
}
