-- ~/.config/nvim-go/init.lua
-- Go layer, used in folders that set NVIM_APPNAME=nvim-go (via that folder's
-- mise.toml). Everywhere else you get the plain config.
--
-- This config is the base config PLUS a Go layer:
--   1. source ~/.config/nvim/init.lua unchanged (single source of truth)
--   2. add gopls on top, wired up with the native LSP client
-- Unlike the Flutter layer there is NO extra plugin: gopls + Neovim's built-in
-- LSP cover everything (go test/build run fine from a terminal split), so this
-- layer adds zero vim.pack plugins of its own. The base config's plugins still
-- get cloned (and pinned in nvim-pack-lock.json) into ~/.local/share/nvim-go,
-- fully isolated from the personal config.

--------------------------------------------------------------------------------
-- 1. Base config (leader, options, fzf, nvim-tree, splits, treesitter, keymaps)
--------------------------------------------------------------------------------
dofile(vim.fn.expand("~/.config/nvim/init.lua"))

--------------------------------------------------------------------------------
-- 2. LSP attach: buffer-local keymaps + native completion + inlay hints
-- Same editor-side wiring as the Flutter layer (Neovim doesn't map LSP keys or
-- enable completion for you); kept identical so muscle memory carries over.
--------------------------------------------------------------------------------
local function on_attach(client, bufnr)
  local function bmap(keys, fn, desc)
    vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
  end
  bmap("gd", vim.lsp.buf.definition,      "Go to definition")
  bmap("gD", vim.lsp.buf.declaration,     "Go to declaration")
  bmap("gi", vim.lsp.buf.implementation,  "Go to implementation")
  bmap("gr", vim.lsp.buf.references,      "References")
  bmap("K",  vim.lsp.buf.hover,           "Hover docs")
  bmap("<leader>rn", vim.lsp.buf.rename,      "Rename symbol")
  bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
  bmap("<leader>d",  vim.diagnostic.open_float, "Line diagnostics")
  bmap("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
  bmap("]d", function() vim.diagnostic.jump({ count =  1 }) end, "Next diagnostic")

  -- Built-in LSP autocompletion (Neovim 0.11+), no nvim-cmp/blink needed.
  if client:supports_method("textDocument/completion") then
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  end
  -- Inlay hints (parameter names, inferred types) — toggle with <leader>th.
  if client:supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    bmap("<leader>th", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
        { bufnr = bufnr })
    end, "Toggle inlay hints")
  end
end

--------------------------------------------------------------------------------
-- 3. gopls via the native client (vim.lsp.config/enable, Neovim 0.11+).
-- Neovim core ships no default gopls config (that lives in nvim-lspconfig, which
-- we don't use), so filetypes + root_markers are spelled out here. gopls itself
-- is the Homebrew binary at /opt/homebrew/bin/gopls.
--------------------------------------------------------------------------------
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  on_attach = on_attach,
  settings = {
    gopls = {
      gofumpt = true,                 -- stricter gofmt
      usePlaceholders = true,         -- fill function args on completion
      staticcheck = true,             -- staticcheck analyzers in diagnostics
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        nilness = true,
        shadow = true,
      },
      hints = {                       -- which inlay hints gopls emits
        assignVariableTypes = true,
        compositeLiteralFields = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})
vim.lsp.enable("gopls")

--------------------------------------------------------------------------------
-- 4. Format + organize imports on save (the goimports behaviour), via gopls.
-- organizeImports first (adds/removes/sorts imports), then a normal LSP format.
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(args)
    local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "gopls" })
    if #clients == 0 then return end
    local enc = clients[1].offset_encoding
    local params = vim.lsp.util.make_range_params(0, enc)
    params.context = { only = { "source.organizeImports" }, diagnostics = {} }
    local result = vim.lsp.buf_request_sync(args.buf, "textDocument/codeAction", params, 1000)
    for _, res in pairs(result or {}) do
      for _, action in pairs(res.result or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, enc)
        end
      end
    end
    vim.lsp.buf.format({ bufnr = args.buf, async = false })
  end,
})
