-- Markdown buffer settings.
--
-- render-markdown.nvim decorates source lines but can't reflow a table cell
-- onto several lines, so with 'wrap' on, wide table rows break at the window
-- edge and the columns stop lining up. Keep rows on one line and scroll
-- sideways (zl / zL / zs / ze) instead.
vim.opt_local.wrap = false

-- <leader>mv: show the buffer in a floating terminal rendered by Rich, which
-- wraps text *inside* table cells to fit the width (like a browser preview).
-- Renders the buffer contents, so unsaved edits show up. Read-only view:
-- scroll with normal-mode motions, q or <Esc> to close.
--
-- Uses `python -m rich.markdown` via uvx rather than rich-cli: rich-cli pins
-- rich<13, which has no markdown table support.
local function rich_view()
  if vim.fn.executable 'uvx' == 0 then
    vim.notify('markdown view: uvx not found (brew install uv)', vim.log.levels.WARN)
    return
  end

  local tmp = vim.fn.tempname() .. '.md'
  vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), tmp)

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local name = vim.fn.expand '%:t'
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. (name ~= '' and name or 'markdown') .. ' ',
    title_pos = 'center',
  })

  vim.fn.jobstart({ 'uvx', '--quiet', '--from', 'rich', 'python', '-m', 'rich.markdown', '-w', tostring(width - 1), tmp }, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        os.remove(tmp)
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_set_cursor(win, { 1, 0 })
        end
      end)
    end,
  })

  for _, key in ipairs { 'q', '<Esc>' } do
    vim.keymap.set('n', key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true })
  end
end

vim.keymap.set('n', '<leader>mv', rich_view, { buffer = true, desc = '[M]arkdown [V]iew (Rich, wrapped tables)' })
