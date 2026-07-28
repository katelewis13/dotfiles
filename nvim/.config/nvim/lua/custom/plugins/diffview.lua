return {
  -- Single tabpage interface for cycling through diffs, plus a git file-history
  -- browser. Complements gitsigns (which is per-hunk) with repo-wide and historical views.
  'sindrets/diffview.nvim',
  cmd = {
    'DiffviewOpen',
    'DiffviewClose',
    'DiffviewFileHistory',
    'DiffviewToggleFiles',
    'DiffviewFocusFiles',
    'DiffviewRefresh',
  },
  keys = {
    {
      '<leader>gd',
      function()
        -- Toggle: close if a Diffview tab is already open, otherwise open one.
        if require('diffview.lib').get_current_view() then
          vim.cmd.DiffviewClose()
        else
          vim.cmd.DiffviewOpen()
        end
      end,
      desc = 'Git [d]iffview toggle (working tree)',
    },
    {
      '<leader>gp',
      function()
        -- Toggle: close if a Diffview tab is already open, otherwise open one.
        if require('diffview.lib').get_current_view() then
          vim.cmd.DiffviewClose()
          return
        end
        -- PR-style diff: working tree (incl. uncommitted changes) against the
        -- merge-base with the default branch — what a GitHub PR shows, plus any
        -- local edits not yet committed.
        local function base_branch()
          -- Prefer the remote's default branch if origin/HEAD is set.
          local head = vim.fn.systemlist('git symbolic-ref --quiet refs/remotes/origin/HEAD')[1]
          if vim.v.shell_error == 0 and head and head ~= '' then
            return head:gsub('^refs/remotes/', '') -- e.g. origin/master
          end
          for _, b in ipairs { 'origin/main', 'origin/master', 'main', 'master' } do
            vim.fn.system('git rev-parse --verify --quiet ' .. b)
            if vim.v.shell_error == 0 then
              return b
            end
          end
          return 'master'
        end
        -- Diff against the merge-base commit (not the base tip), so commits that
        -- landed on the base after we branched don't pollute the view. Omitting a
        -- right-hand side makes diffview compare against the working tree, so
        -- uncommitted changes show up too.
        local merge_base = vim.fn.systemlist('git merge-base ' .. base_branch() .. ' HEAD')[1]
        if vim.v.shell_error ~= 0 or not merge_base or merge_base == '' then
          vim.notify('Could not find merge-base with default branch', vim.log.levels.ERROR)
          return
        end
        vim.cmd('DiffviewOpen ' .. merge_base)
      end,
      desc = 'Git [p]R-style diff (branch vs base)',
    },
    { '<leader>gh', '<cmd>DiffviewFileHistory<cr>', desc = 'Git repo [h]istory' },
    { '<leader>gf', '<cmd>DiffviewFileHistory %<cr>', desc = 'Git current [f]ile history' },
  },
  opts = {},
  config = function(_, opts)
    require('diffview').setup(opts)

    -- VSCode-style side-aware diff colours. Neovim's diff engine paints a
    -- changed line with the SAME DiffChange/DiffText on both panes, so a
    -- partial, in-line edit shows one colour on each side. Remap those two
    -- groups per window via `winhighlight` so the old (left) pane renders
    -- changes in red and the new (right) pane in green — the changed line
    -- gets a soft wash, the exact changed characters a stronger tint (the
    -- …Old/…New groups are defined in tokyonight's on_highlights in init.lua).
    -- Whole added/deleted lines already use DiffAdd/DiffDelete (green/red) and
    -- are left untouched.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'DiffviewDiffBufWinEnter',
      group = vim.api.nvim_create_augroup('diffview_side_hl', { clear = true }),
      callback = function()
        local ok, lib = pcall(require, 'diffview.lib')
        if not ok then
          return
        end
        local view = lib.get_current_view()
        local layout = view and view.cur_layout
        -- Only the standard 2-way diff (old = a, new = b). A 3-way merge layout
        -- has a `.c` window, where red/green old-vs-new is ambiguous — skip it.
        if not layout or layout.c or not (layout.a and layout.b) then
          return
        end
        local sides = {
          [layout.a.id] = 'DiffChange:DiffChangeOld,DiffText:DiffTextOld',
          [layout.b.id] = 'DiffChange:DiffChangeNew,DiffText:DiffTextNew',
        }
        for winid, winhl in pairs(sides) do
          if winid and vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_set_option_value('winhighlight', winhl, { win = winid })
          end
        end
      end,
    })

    -- Diffview remaps every fold command in its diff buffers to wrapper
    -- functions tagged `desc = "diffview_ignore"` (see diffview/actions.lua).
    -- which-key reads that desc verbatim and shows "diffview ignore". Since
    -- which-key adds `spec`/`add` mappings AFTER real keymaps and last-write
    -- wins per node, a buffer-local add with real descriptions overrides the
    -- label — scoped to diff buffers so `z` stays silent elsewhere.
    local fold_labels = {
      { 'z', group = 'Fold' },
      { 'za', desc = 'Toggle fold' },
      { 'zo', desc = 'Open fold' },
      { 'zc', desc = 'Close fold' },
      { 'zO', desc = 'Open fold recursively' },
      { 'zC', desc = 'Close fold recursively' },
      { 'zr', desc = 'Open one more fold level (file)' },
      { 'zm', desc = 'Close one more fold level (file)' },
      { 'zR', desc = 'Open all folds' },
      { 'zM', desc = 'Close all folds' },
      { 'zv', desc = 'Reveal cursor line' },
    }

    vim.api.nvim_create_autocmd('User', {
      pattern = 'DiffviewDiffBufWinEnter',
      group = vim.api.nvim_create_augroup('diffview_fold_labels', { clear = true }),
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        -- Config.add appends without dedup, so only register once per buffer.
        if vim.b[buf].wk_fold_labels then
          return
        end
        local ok, wk = pcall(require, 'which-key')
        if not ok then
          return
        end
        vim.b[buf].wk_fold_labels = true
        local spec = {}
        for _, m in ipairs(fold_labels) do
          spec[#spec + 1] = vim.tbl_extend('force', m, { buffer = buf })
        end
        wk.add(spec)
      end,
    })
  end,
}
