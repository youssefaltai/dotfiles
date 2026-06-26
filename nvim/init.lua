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
  { src = "https://github.com/rebelot/kanagawa.nvim" },  -- colorscheme
  { src = "https://github.com/ibhagwan/fzf-lua" },       -- fuzzy finder (fzf/rg/fd)
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
map("n", "<Esc>",     "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
