return {
  {
    'nvim-flutter/flutter-tools.nvim',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Resolve FVM flutter binary: project-local first, then global FVM, then PATH
      local function get_flutter_path()
        local project_flutter = vim.fn.getcwd() .. '/.fvm/flutter_sdk/bin/flutter'
        if vim.fn.filereadable(project_flutter) == 1 then return project_flutter end
        local global_flutter = vim.fn.expand('$HOME/fvm/default/bin/flutter')
        if vim.fn.filereadable(global_flutter) == 1 then return global_flutter end
        return nil  -- fall back to PATH
      end

      require('flutter-tools').setup {
        flutter_path = get_flutter_path(),
        ui = { border = 'rounded' },
        widget_guides = { enabled = true },
        closing_tags = { enabled = true, highlight = 'Comment', prefix = '  // ' },
        dev_log = { enabled = true, open_cmd = '15split', notify_errors = true },
        debugger = {
          enabled = true,
          run_via_dap = true,
          exception_breakpoints = {},
        },
        lsp = {
          color = { enabled = true, virtual_text = true, virtual_text_str = '■' },
          capabilities = require('blink.cmp').get_lsp_capabilities(),
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            analysisExcludedFolders = {
              vim.fn.expand('$HOME/.pub-cache'),
              vim.fn.expand('$HOME/fvm/versions'),
            },
            enableSnippets = true,
            updateImportsOnRename = true,
          },
        },
      }

      -- Keymaps under <leader>F (Flutter)
      local map = function(k, cmd, desc)
        vim.keymap.set('n', k, cmd, { desc = 'Flutter: ' .. desc })
      end
      map('<leader>Fs', '<cmd>FlutterRun<cr>',            '[S]tart app')
      map('<leader>Fq', '<cmd>FlutterQuit<cr>',           '[Q]uit app')
      map('<leader>Fr', '<cmd>FlutterReload<cr>',         'Hot [R]eload')
      map('<leader>FR', '<cmd>FlutterRestart<cr>',        'Hot [R]estart')
      map('<leader>Fd', '<cmd>FlutterDevices<cr>',        '[D]evices')
      map('<leader>Fe', '<cmd>FlutterEmulators<cr>',      '[E]mulators')
      map('<leader>Fo', '<cmd>FlutterOutlineToggle<cr>',  '[O]utline')
      map('<leader>Fl', '<cmd>FlutterLogClear<cr>',       '[L]og clear')
    end,
  },
}
