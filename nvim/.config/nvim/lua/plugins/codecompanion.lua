return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  cmd = {
    'CodeCompanion',
    'CodeCompanionChat',
    'CodeCompanionCmd',
    'CodeCompanionActions',
  },
  keys = {
    { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = '[A]I [A]ction palette' },
    { '<leader>ac', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = '[A]I [C]hat toggle' },
    { '<leader>ai', ':CodeCompanion ', mode = { 'n', 'v' }, desc = '[A]I [I]nline prompt' },
    { '<leader>ad', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = '[A]I a[D]d selection to chat' },
  },
  opts = function()
    local opts = {
      display = {
        chat = {
          window = {
            layout = 'vertical',
            width = 0.35,
          },
        },
        diff = {
          provider = 'default',
        },
      },
    }

    -- Adapter and auth config is delegated to lua/private/codecompanion.lua,
    -- which is gitignored so this config isn't tied to a specific provider.
    -- Merged in when present, skipped otherwise.
    local ok, private = pcall(require, 'private.codecompanion')
    if ok then
      opts = vim.tbl_deep_extend('force', opts, private)
    end

    return opts
  end,
}
