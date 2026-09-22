-- Git diff review: the VSCode "Source Control" equivalent -- a changed-files
-- panel on the left, a real side-by-side diff on the right, and file-by-file
-- navigation through a whole commit / branch / range.
--
-- Complements gitsigns rather than replacing it: gitsigns stays the in-buffer
-- layer (gutter signs, hunk preview/stage/reset under <leader>h), diffview is
-- the "review the whole changeset" layer under <leader>g.
--
-- All terminal UI, so it works over SSH and inside tmux.

-- Review the current branch against where it diverged from the upstream default
-- branch -- the "what's in this PR" view. Resolved at keypress rather than at
-- startup because the default branch differs per repo (main vs master).
local function diff_branch()
  local function default_branch()
    local ref = vim.fn.systemlist 'git symbolic-ref --short refs/remotes/origin/HEAD'
    if vim.v.shell_error == 0 and ref[1] and ref[1] ~= '' then
      return ref[1]
    end
    for _, candidate in ipairs { 'origin/main', 'origin/master' } do
      vim.fn.system('git rev-parse --verify --quiet ' .. candidate)
      if vim.v.shell_error == 0 then
        return candidate
      end
    end
    return nil
  end

  local base = default_branch()
  if not base then
    vim.notify('diffview: no origin/HEAD, origin/main or origin/master found', vim.log.levels.WARN)
    return
  end
  -- Three-dot range: diff against the merge-base, so upstream commits that
  -- landed since you branched don't show up as your changes.
  vim.cmd('DiffviewOpen ' .. base .. '...HEAD')
end

-- Small-screen "solo" mode: hide the file panel and collapse the old version so
-- the new version gets the whole window. Toggled with <leader>z from inside a
-- diff; toggling again restores the panel and the side-by-side split.
local function panel_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft == 'DiffviewFiles' or ft == 'DiffviewFileHistory' then
      return win
    end
  end
end

-- winminwidth has to drop to 0 or the collapsed pane keeps a 1-column sliver.
-- It's a global option, so stash the real value and put it back on the way out.
local function restore_winminwidth()
  if vim.g.dv_winminwidth ~= nil then
    vim.o.winminwidth = vim.g.dv_winminwidth
    vim.g.dv_winminwidth = nil
  end
end

local function toggle_solo()
  if vim.t.dv_solo then
    vim.t.dv_solo = false
    restore_winminwidth()
    if not panel_win() then
      vim.cmd 'DiffviewToggleFiles'
    end
    vim.cmd 'wincmd ='
  else
    vim.t.dv_solo = true
    vim.g.dv_winminwidth = vim.o.winminwidth
    vim.o.winminwidth = 0
    if panel_win() then
      vim.cmd 'DiffviewToggleFiles'
    end
    vim.cmd 'wincmd |'
  end
end

---@module 'lazy'
---@type LazySpec
return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },

  -- Lazy-loaded: the commands and the <leader>g keys below are the triggers, so
  -- this costs nothing at startup.
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles', 'DiffviewRefresh' },

  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Git [d]iff working tree' },
    { '<leader>gb', diff_branch, desc = 'Git diff [b]ranch vs default' },
    { '<leader>gc', '<cmd>DiffviewOpen HEAD~1<cr>', desc = 'Git diff last [c]ommit' },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Git [h]istory of this file' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = 'Git [H]istory of repo' },
    { '<leader>gf', '<cmd>DiffviewToggleFiles<cr>', desc = 'Git diff toggle [f]ile panel' },
    { '<leader>gq', '<cmd>DiffviewClose<cr>', desc = 'Git diff [q]uit' },
    -- Visual mode: history of just the selected lines (git log -L under the hood).
    { '<leader>gh', ":'<,'>DiffviewFileHistory<cr>", mode = 'v', desc = 'Git [h]istory of selection' },
  },

  init = function()
    -- Diffview rebuilds its window layout as you move between files, which would
    -- undo the zoom -- re-apply it while solo mode is on, and make sure the
    -- global winminwidth gets restored if the view is closed while soloed.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'DiffviewDiffBufWinEnter',
      callback = function()
        if vim.t.dv_solo then
          vim.cmd 'wincmd |'
        end
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      pattern = 'DiffviewViewClosed',
      callback = restore_winminwidth,
    })
  end,

  ---@module 'diffview'
  opts = {
    enhanced_diff_hl = true, -- better add/change highlighting than the plain diff colors
    view = {
      merge_tool = {
        layout = 'diff3_mixed', -- base in the middle when resolving conflicts
        disable_diagnostics = true, -- LSP errors on half-merged files are just noise
      },
    },
    file_panel = {
      listing_style = 'tree',
      win_config = { width = 26 }, -- narrow: this is a laptop-sized screen
    },
    keymaps = {
      view = {
        { 'n', '<leader>z', toggle_solo, { desc = 'Diffview: solo the current version' } },
      },
    },
  },
}
