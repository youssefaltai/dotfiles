-- ~/.config/nvim-flutter/init.lua
-- Flutter/Dart layer, used ONLY in ~/work/reckit/ via NVIM_APPNAME=nvim-flutter
-- (set in ~/work/reckit/mise.toml). Everywhere else you get the plain config.
--
-- This config is the base config PLUS a Flutter layer:
--   1. source ~/.config/nvim/init.lua unchanged (single source of truth)
--   2. add the Dart LSP + flutter-tools.nvim on top
-- Plugins/state for this layer live under ~/.local/share/nvim-flutter, fully
-- isolated from the personal config — nothing here leaks into other work.

--------------------------------------------------------------------------------
-- 1. Base config (leader, options, fzf, nvim-tree, splits, treesitter, keymaps)
--------------------------------------------------------------------------------
dofile(vim.fn.expand("~/.config/nvim/init.lua"))

--------------------------------------------------------------------------------
-- 2. Flutter layer plugins (own pack dir under ~/.local/share/nvim-flutter)
--------------------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },        -- dep of flutter-tools
  { src = "https://github.com/akinsho/flutter-tools.nvim" },   -- run/reload/devices + dartls
})

--------------------------------------------------------------------------------
-- flutter-tools: fvm = true makes it use <project>/.fvm/flutter_sdk, so each
-- repo's pinned SDK (.fvmrc) is honored — correct for the reckit monorepo.
-- LSP keymaps and documentColor are handled by the base config's LspAttach
-- autocmd — no on_attach callback needed here.
--------------------------------------------------------------------------------
require("flutter-tools").setup({
  fvm = true,
  lsp = {
    settings = {
      showTodos = true,
      completeFunctionCalls = true,
      enableSnippets = true,
      updateImportsOnRename = true,
      renameFilesWithClasses = "prompt",
    },
  },
})

--------------------------------------------------------------------------------
-- Flutter commands  (<leader>F… prefix; <leader>f… stays the fuzzy finder)
--------------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>Fr", "<cmd>FlutterRun<cr>",           { desc = "Flutter run" })
map("n", "<leader>Fl", "<cmd>FlutterReload<cr>",        { desc = "Flutter hot reload" })
map("n", "<leader>FR", "<cmd>FlutterRestart<cr>",       { desc = "Flutter hot restart" })
map("n", "<leader>Fq", "<cmd>FlutterQuit<cr>",          { desc = "Flutter quit" })
map("n", "<leader>Fd", "<cmd>FlutterDevices<cr>",       { desc = "Flutter devices" })
map("n", "<leader>Fe", "<cmd>FlutterEmulators<cr>",     { desc = "Flutter emulators" })
map("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", { desc = "Flutter widget outline" })
map("n", "<leader>FD", "<cmd>FlutterDevTools<cr>",      { desc = "Flutter DevTools" })
map("n", "<leader>Fc", "<cmd>FlutterLogClear<cr>",      { desc = "Flutter clear log" })
