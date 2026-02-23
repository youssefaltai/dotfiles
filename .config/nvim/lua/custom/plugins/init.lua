-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate to left pane/window' },
      { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate to down pane/window' },
      { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate to up pane/window' },
      { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate to right pane/window' },
      { '<C-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Navigate to previous pane/window' },
    },
  },
}
