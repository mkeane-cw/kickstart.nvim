-- In-buffer markdown rendering: headings, code blocks, tables, checkboxes,
-- blockquotes etc. render inline in Neovim itself -- no browser, no node/deno,
-- so it works fine over SSH and inside tmux (which is where I usually am).
--
-- Uses the treesitter `markdown` + `markdown_inline` parsers that init.lua
-- already installs, and nvim-web-devicons for language icons in fenced blocks.

---@module 'lazy'
---@type LazySpec
return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  ft = { 'markdown' },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
  config = function(_, opts)
    require('render-markdown').setup(opts)

    -- Toggle the rendered view on/off. Rendering is on by default when a
    -- markdown buffer opens; <leader>tm flips to raw source and back.
    vim.keymap.set('n', '<leader>tm', function()
      require('render-markdown').toggle()
    end, { desc = '[T]oggle [M]arkdown render' })
  end,
}
