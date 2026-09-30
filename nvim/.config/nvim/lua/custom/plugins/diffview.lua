-- Resolve the branch this one was cut from: prefer the remote's default branch
-- if origin/HEAD is set, then fall back through the usual suspects.
local function base_branch()
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

-- The commit where this branch diverged from its base. Diffing/logging against
-- the merge-base rather than the base *tip* keeps commits that landed on the
-- base after we branched out of the view. Returns nil (and notifies) on failure.
local function merge_base()
  local rev = vim.fn.systemlist('git merge-base ' .. base_branch() .. ' HEAD')[1]
  if vim.v.shell_error ~= 0 or not rev or rev == '' then
    vim.notify('Could not find merge-base with default branch', vim.log.levels.ERROR)
    return nil
  end
  return rev
end

-- Close the Diffview tab we're sitting in, if any, and report whether we did —
-- lets each mapping be a toggle via `if closed_existing() then return end`.
-- Closing the view tears down all its diff buffers in one go.
local function closed_existing()
  if require('diffview.lib').get_current_view() then
    vim.cmd.DiffviewClose()
    return true
  end
  return false
end

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
        if closed_existing() then
          return
        end
        vim.cmd.DiffviewOpen()
      end,
      desc = 'Git [d]iffview toggle (working tree)',
    },
    {
      '<leader>gp',
      function()
        if closed_existing() then
          return
        end
        -- PR-style diff: working tree (incl. uncommitted changes) against the
        -- merge-base with the default branch — what a GitHub PR shows, plus any
        -- local edits not yet committed. Omitting a right-hand side is what
        -- makes diffview compare against the working tree.
        local rev = merge_base()
        if rev then
          vim.cmd('DiffviewOpen ' .. rev)
        end
      end,
      desc = 'Git [p]R-style diff (branch vs base)',
    },
    {
      '<leader>gc',
      function()
        if closed_existing() then
          return
        end
        -- Commits on this branch only. The file-history panel lists them
        -- newest-first; <CR> on a commit expands it into its changed files,
        -- each opening as a normal two-pane diff of that single commit.
        local rev = merge_base()
        if rev then
          vim.cmd('DiffviewFileHistory --range=' .. rev .. '..HEAD')
        end
      end,
      desc = 'Git branch [c]ommits (this branch vs base)',
    },
    {
      '<leader>gh',
      function()
        if closed_existing() then
          return
        end
        vim.cmd.DiffviewFileHistory()
      end,
      desc = 'Git repo [h]istory',
    },
    {
      '<leader>gf',
      function()
        if closed_existing() then
          return
        end
        -- Expand `%` here rather than passing it through: DiffviewFileHistory
        -- resolves paths against the cwd, and the buffer name may be relative
        -- to something else.
        vim.cmd('DiffviewFileHistory ' .. vim.fn.fnameescape(vim.fn.expand '%:p'))
      end,
      desc = 'Git current [f]ile history',
    },
  },
  opts = {},
  config = function(_, opts)
    require('diffview').setup(opts)

    -- Keep the unchanged parts of the file visible. Diffview opens each diff
    -- window with `foldmethod=diff`, `foldlevel=0`, so every run of unchanged
    -- lines starts collapsed; bumping foldlevel opens them while leaving the
    -- folds themselves in place, so zm/zM still work when the context gets in
    -- the way.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'DiffviewDiffBufWinEnter',
      group = vim.api.nvim_create_augroup('diffview_open_folds', { clear = true }),
      callback = function()
        -- Diffview emits this from inside the diff window itself, so the
        -- current window is the one to unfold.
        vim.wo.foldlevel = 99
      end,
    })

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
