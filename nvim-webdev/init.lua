-- ~/.config/nvim-webdev/init.lua
-- Web dev layer (JS/TS/React/CSS/HTML), used via NVIM_APPNAME=nvim-webdev.
-- Sourced from mise.toml in web project roots, or via `alias nvim-web='NVIM_APPNAME=nvim-webdev nvim'`.
--
-- Design mirrors nvim-flutter:
--   1. source ~/.config/nvim/init.lua (single source of truth for options/keymaps)
--   2. add TypeScript/JavaScript language server + debugger on top
-- Plugins/state live under ~/.local/share/nvim-webdev, fully isolated.

-------------------------------------------------------------------------------
-- 1. Base config (leader, options, fzf, tree, splits, LspAttach keymaps, …)
-------------------------------------------------------------------------------
dofile(vim.fn.expand("~/.config/nvim/init.lua"))

-------------------------------------------------------------------------------
-- 2. Web dev plugins
-------------------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/mfussenegger/nvim-dap" },            -- Debug Adapter Protocol
})

-------------------------------------------------------------------------------
-- 3. TypeScript / JavaScript language server
-- Uses the native 0.12 API (vim.lsp.config + vim.lsp.enable), NOT the
-- deprecated require('lspconfig') framework.
-- Install the server: npm install -g typescript-language-server
-- (TypeScript itself lives in each project's node_modules.)
-- root_markers tells the client to walk up from the buffer to find the
-- project root, so the server finds node_modules/typescript correctly.
-------------------------------------------------------------------------------
vim.lsp.config('ts_ls', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json' },
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
      },
    },
  },
})
vim.lsp.enable('ts_ls')

-------------------------------------------------------------------------------
-- 4. nvim-dap (Node.js / Chrome debugger)
-- Install js-debug-adapter: npm install -g @vscode/js-debug-adapter
-------------------------------------------------------------------------------
local dap = require('dap')
dap.adapters['pwa-node'] = {
  type = 'server',
  host = '127.0.0.1',
  port = 9229,
}
dap.configurations.typescript = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch file',
    program = '${file}',
    cwd = '${workspaceFolder}',
    runtimeExecutable = 'node',
  },
  {
    type = 'pwa-node',
    request = 'attach',
    name = 'Attach to process',
    processId = require('dap.utils').pick_process,
    cwd = '${workspaceFolder}',
  },
}
dap.configurations.typescriptreact = dap.configurations.typescript
dap.configurations.javascript = dap.configurations.typescript
dap.configurations.javascriptreact = dap.configurations.typescript
