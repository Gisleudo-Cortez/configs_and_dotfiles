-- keylight context provider — pairs with ~/Projects/keylight (Python daemon).
-- Pure observer: reports focus/mode context and dumps nvim's real keymap
-- families to the shared state dir. It remaps nothing; all key physics
-- live in the daemon's evdev listener.
--
-- state.json   : { active = <focused AND normal mode> }   (daemon reads live)
-- keymaps.json : { families = { "f", "c", "g", ... } }     (dumped at startup)
--
-- v1 scope: single primary nvim session assumed. A second unfocused instance
-- writing state.json would clobber focus state; families are identical for
-- any instance of the same config, so only focus tracking can race.

local state_dir  = vim.fn.expand("~/.local/state/keylight")
local state_file = state_dir .. "/state.json"

local M = {}

local function write_json(obj)
  vim.fn.mkdir(state_dir, "p")
  local tmp = state_file .. ".tmp"
  vim.fn.writefile({ vim.json.encode(obj) }, tmp)
  os.rename(tmp, state_file)
end

local function active_now()
  -- Focus is tracked by FocusGained/FocusLost autocmds (set below); no
  -- win-count heuristics — nvim 0.11 renamed those APIs and the previous
  -- form crashed VimLeavePre in headless mode.
  return M.focused == true and M.mode == "n"
end

local function push_state()
  local ok, _ = pcall(write_json, { active = active_now() and true or false })
  if not ok then end  -- never let cosmetic state writes disturb editing
end

local function dump_families()
  -- First character of every <leader> mapping: the families the daemon
  -- lights while Space is held. Uses the LIVE keymap table, so plugin
  -- mappings registered through lazy keys= are included automatically.
  local seen, fams = {}, {}
  local ok, maps = pcall(vim.api.nvim_get_keymap, "n")
  if not ok then return end
  for _, m in ipairs(maps) do
    local lhs = (m.lhs or ""):lower()
    local fam = lhs:match("^<leader>(.)")
      or lhs:match("^ (.)")
    if fam and not seen[fam] then
      seen[fam] = true
      fams[#fams + 1] = fam
    end
  end
  local km = state_dir .. "/keymaps.json"
  local tmp = km .. ".tmp"
  vim.fn.mkdir(state_dir, "p")
  vim.fn.writefile({ vim.json.encode({ families = fams }) }, tmp)
  os.rename(tmp, km)
end

local function update_mode()
  M.mode = vim.api.nvim_get_mode().mode == "n" and "n" or nil
  push_state()
end

local group = vim.api.nvim_create_augroup("Keylight", { clear = true })
local on = function(events, fn)
  vim.api.nvim_create_autocmd(events, { group = group, callback = fn })
end

on("FocusGained", function() M.focused = true; push_state() end)
on("FocusLost",   function() M.focused = false; push_state() end)
on("InsertEnter", update_mode)
on("InsertLeave", update_mode)
on("VimLeavePre", function() M.focused = false; push_state() end)
on("VimResume",   function() M.focused = true; push_state() end)
on("VimSuspend",  function() M.focused = false; push_state() end)

-- Manual refresh: re-dump families without restarting nvim (useful after
-- installing plugins that add leader maps mid-session).
vim.api.nvim_create_user_command("KeylightDump", function()
  dump_families()
end, { desc = "keylight: refresh leader-family dump" })

-- Script-load-time init. lazy.nvim sources after/plugin files DURING the
-- VimEnter dispatch, so a VimEnter handler registered here would never
-- fire (registration mid-event = miss on the current occurrence). At load
-- time config.keymaps has already run (after/plugin is sourced after all
-- of init.lua), so the immediate dump is guaranteed to see the global
-- leader maps; the deferred pass catches lazy plugin keys moments later.
M.focused = true
update_mode()
dump_families()
vim.defer_fn(dump_families, 1000)

return M