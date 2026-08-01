-- ~/.config/nvim/init.lua
-- Minimal Neovim 0.12 config. Single file on purpose: readable top-to-bottom.
-- Plugins via the built-in `vim.pack` (no third-party plugin manager).
-- LSP keymaps live in the LspAttach autocmd below — harmless in the base config
-- because it only fires when a language server attaches. Per-language servers
-- are added via NVIM_APPNAME layers (nvim-webdev, nvim-flutter, etc.).

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
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },       -- docked sidebar file tree
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },   -- file-type icons (needs a Nerd Font)
  { src = "https://github.com/mrjones2014/smart-splits.nvim" }, -- seamless nvim<->tmux pane nav
  { src = "https://github.com/folke/flash.nvim" },              -- jump anywhere on screen in a few keystrokes
  { src = "https://github.com/folke/which-key.nvim" },         -- keymap discoverability
  { src = "https://github.com/lewis6991/gitsigns.nvim" },     -- git signs in the gutter
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },  -- parser management (:TSInstall)
})

-- Colorscheme
vim.cmd.colorscheme("kanagawa")

-- Treesitter parser management (minimal — just for :TSInstall / :TSUpdate).
-- Highlighting is handled by the built-in autocmd below, not nvim-treesitter.
-- Run `:TSInstall javascript typescript tsx css html json` once for web dev.
-- pcall handles the first-launch race where vim.pack is still cloning the repo.
pcall(function()
  require("nvim-treesitter.configs").setup({
    auto_install = false,
    highlight = { enable = false },
  })
end)

-- Keymap discoverability (which-key)
-- Shows a popup with available mappings on <leader> pause.
-- Leader-only triggers keep it from showing on every g/z keystroke.
local wk = require("which-key")
wk.setup({ triggers = { { "<leader>", mode = { "n", "v" } } } })
wk.add({ { "<leader>f", group = "Find" } })

-- Fuzzy finder + keymaps
local fzf = require("fzf-lua")
fzf.setup({})
local map = vim.keymap.set
map("n", "<leader>ff", fzf.files,     { desc = "Find files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", fzf.buffers,   { desc = "Buffers" })
map("n", "<leader>fh", fzf.help_tags,             { desc = "Help tags" })
-- LSP-aware fzf-lua pickers (safe in base — require a server to be attached)
map("n", "<leader>fs", fzf.lsp_document_symbols,  { desc = "Document symbols" })
map("n", "<leader>fS", fzf.lsp_workspace_symbols, { desc = "Workspace symbols" })
map("n", "<leader>fr", fzf.lsp_references,         { desc = "References" })
map("n", "<leader>fd", fzf.diagnostics_document,   { desc = "Document diagnostics" })
map("n", "<leader>fD", fzf.diagnostics_workspace,  { desc = "Workspace diagnostics" })

-- File explorer (nvim-tree): a docked sidebar tree on the left.
-- `<leader>e` toggles it; inside the tree `<CR>` opens, `a` creates, `d` deletes,
-- `r` renames, `?` shows all mappings. netrw is disabled so the tree owns `-`/dirs.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
  view = { width = 35 },                       -- sidebar width
  renderer = { group_empty = true },           -- collapse chains of empty dirs
  filters = { dotfiles = false },              -- show hidden files (matches old oil setup)
  update_focused_file = { enable = true },     -- follow the file in the active buffer
})
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>",   { desc = "Toggle file tree" })
map("n", "<leader>E", "<cmd>NvimTreeFindFile<cr>", { desc = "Reveal file in tree" })

--------------------------------------------------------------------------------
-- Seamless navigation between nvim splits and tmux panes
-- Ctrl-h/j/k/l moves the cursor; at the edge of nvim it hands off to the
-- adjacent tmux pane (and back). The tmux side (see ~/.config/tmux/tmux.conf)
-- routes these keys into nvim whenever the focused pane is running nvim, so the
-- handoff is seamless both ways without scanning processes on every press.
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
-- Start it for any buffer that has an installed parser (pcall = silent if
-- none). Install parsers via nvim-treesitter's :TSInstall (registered above).
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

--------------------------------------------------------------------------------
-- Generic LSP attach: buffer-local keymaps and native features
-- Fires for any language server from any NVIM_APPNAME layer, so it lives in
-- the base config. Per-language server config goes in the layer's init.lua.
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end
    local opts = { buffer = ev.buf }

    -- Standard LSP navigation and actions
    vim.keymap.set("n", "gd", vim.lsp.buf.definition,          opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration,         opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation,      opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references,          opts)
    vim.keymap.set("n", "K",  vim.lsp.buf.hover,               opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,          opts)
    vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, opts)

    -- Diagnostic navigation
    vim.keymap.set("n", "<leader>d",  vim.diagnostic.open_float,    opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count =  1 }) end, opts)

    -- Inline color swatches (0.12+ native API)
    if client:supports_method("textDocument/documentColor") then
      vim.lsp.document_color.enable(true, { bufnr = ev.buf })
    end
  end,
})

--------------------------------------------------------------------------------
-- Git signs in the gutter (gitsigns)
-- Auto-starts for any git-tracked file. Keymaps are buffer-local.
--------------------------------------------------------------------------------
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local function bmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    -- Hunk navigation (falls back to native diff-mode ]c/[c)
    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then return "]c" end
      vim.schedule(function() gs.next_hunk() end)
      return "<Ignore>"
    end, { buffer = bufnr, expr = true, desc = "Next hunk" })
    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then return "[c" end
      vim.schedule(function() gs.prev_hunk() end)
      return "<Ignore>"
    end, { buffer = bufnr, expr = true, desc = "Prev hunk" })
    -- Stage / reset / blame / preview
    bmap("n", "<leader>hs", gs.stage_hunk,       "Stage hunk")
    bmap("n", "<leader>hr", gs.reset_hunk,       "Reset hunk")
    bmap("n", "<leader>hp", gs.preview_hunk,     "Preview hunk")
    bmap("n", "<leader>hb", gs.blame_line,       "Blame line")
    bmap("n", "<leader>hd", gs.diffthis,         "Diff this")
    bmap("n", "<leader>hu", gs.undo_stage_hunk,  "Undo stage hunk")
  end,
})

--------------------------------------------------------------------------------
-- Quality-of-life keymaps
--------------------------------------------------------------------------------
map("n", "<leader>w", "<cmd>write<cr>",   { desc = "Save file" })
map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "Close buffer" })
map("n", "<Esc>",     "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
