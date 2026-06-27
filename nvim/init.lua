-- ~/.config/nvim/init.lua
-- Minimal Neovim 0.12 config. Single file on purpose: readable top-to-bottom.
-- Plugins via the built-in `vim.pack` (no third-party plugin manager).
-- LSP + completion are intentionally NOT here yet — we add them per-language
-- as a clean next step once your stack is known.

--------------------------------------------------------------------------------
-- Leader key  (set BEFORE any mapping so every mapping sees it)
--------------------------------------------------------------------------------
vim.g.mapleader = " "        -- Space as the leader key
vim.g.maplocalleader = " "

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------
local o = vim.opt
o.number = true              -- absolute number on the cursor line
o.relativenumber = true      -- relative numbers elsewhere (fast j/k motions)
o.mouse = "a"                -- enable mouse in all modes
o.clipboard = "unnamedplus"  -- use the macOS system clipboard
o.undofile = true            -- persist undo history across sessions
o.ignorecase = true          -- case-insensitive search...
o.smartcase = true           -- ...unless the query contains a capital letter
o.signcolumn = "yes"         -- always show sign column (prevents text shifting)
o.termguicolors = true       -- 24-bit color (modern colorschemes need this)
o.scrolloff = 8              -- keep 8 lines of context above/below the cursor
o.splitright = true          -- vertical splits open to the right
o.splitbelow = true          -- horizontal splits open below
o.expandtab = true           -- indent with spaces, not tabs
o.shiftwidth = 2             -- size of an indent
o.tabstop = 2                -- a <Tab> shows as 2 spaces
o.smartindent = true         -- language-aware autoindent
o.wrap = false               -- don't soft-wrap long lines
o.cursorline = true          -- highlight the line the cursor is on

--------------------------------------------------------------------------------
-- Plugins  (built-in vim.pack — clones missing plugins on first launch)
--------------------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/rebelot/kanagawa.nvim" },         -- colorscheme
  { src = "https://github.com/ibhagwan/fzf-lua" },              -- fuzzy finder (fzf/rg/fd)
  { src = "https://github.com/stevearc/oil.nvim" },             -- file explorer (edit fs as a buffer)
  { src = "https://github.com/mrjones2014/smart-splits.nvim" }, -- seamless nvim<->tmux pane nav
  { src = "https://github.com/folke/flash.nvim" },              -- jump anywhere on screen in a few keystrokes
})

-- Colorscheme
vim.cmd.colorscheme("kanagawa")

-- Fuzzy finder + keymaps
local fzf = require("fzf-lua")
fzf.setup({})
local map = vim.keymap.set
map("n", "<leader>ff", fzf.files,     { desc = "Find files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", fzf.buffers,   { desc = "Buffers" })
map("n", "<leader>fh", fzf.help_tags, { desc = "Help tags" })

-- File explorer (oil): browse and edit the filesystem like a normal buffer.
-- `-` opens the parent dir; edit lines then `:w` to apply (create/rename/delete).
require("oil").setup({
  default_file_explorer = true,            -- take over from netrw
  view_options = { show_hidden = true },   -- show dotfiles
})
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent dir (oil)" })

--------------------------------------------------------------------------------
-- Seamless navigation between nvim splits and tmux panes
-- Ctrl-h/j/k/l moves the cursor; at the edge of nvim it hands off to the
-- adjacent tmux pane (and back). smart-splits sets the tmux @pane-is-vim
-- variable so the tmux side (see ~/.config/tmux/tmux.conf) routes these keys
-- without scanning processes on every press — fast, no lag.
--------------------------------------------------------------------------------
local ss = require("smart-splits")
ss.setup({ at_edge = "stop" })  -- at the outermost edge, stay put (don't wrap)
map("n", "<C-h>", ss.move_cursor_left,  { desc = "Go to split/pane left" })
map("n", "<C-j>", ss.move_cursor_down,  { desc = "Go to split/pane down" })
map("n", "<C-k>", ss.move_cursor_up,    { desc = "Go to split/pane up" })
map("n", "<C-l>", ss.move_cursor_right, { desc = "Go to split/pane right" })

--------------------------------------------------------------------------------
-- Jump anywhere on screen (flash.nvim)
-- `s` then 2 chars labels every match on screen — tap a label to jump there.
-- setup() also upgrades the built-in f/t/F/T into multi-line, labelled hops, so
-- the motions you already use reach further for free. `S` jumps by treesitter
-- node (structural select/jump). The native `s`/`S` (substitute) are gone —
-- use `cl`/`cc`, which do exactly the same edit.
--------------------------------------------------------------------------------
local flash = require("flash")
flash.setup({})
map({ "n", "x", "o" }, "s", flash.jump,       { desc = "Flash jump" })
map({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash treesitter select" })

--------------------------------------------------------------------------------
-- Built-in treesitter highlighting
-- 0.12 ships parsers for common languages, so highlighting needs no plugin.
-- Start it for any buffer that has a bundled parser (pcall = silent if none).
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

--------------------------------------------------------------------------------
-- Quality-of-life keymaps
--------------------------------------------------------------------------------
map("n", "<leader>w", "<cmd>write<cr>",   { desc = "Save file" })
map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "Close buffer" })
map("n", "<Esc>",     "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
