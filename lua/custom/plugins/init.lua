-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  -- Python debugging for mcp/splat via nvim-dap.
  -- kickstart.plugins.debug provides nvim-dap + dap-ui + the debugpy adapter
  -- (installed by Mason). This wires debugpy up to a Python interpreter,
  -- preferring the repo's uv-managed venv so breakpoints run with the project's
  -- own dependencies importable.
  {
    'mfussenegger/nvim-dap-python',
    dependencies = { 'mfussenegger/nvim-dap' },
    ft = 'python',
    config = function()
      -- Prefer the repo's uv venv (needs `uv add --dev debugpy`); sessionize
      -- opens nvim already in the repo root, so cwd is the project here. Fall
      -- back to the Mason-installed debugpy for venv-less / stdlib-only scripts.
      local function debugpy_python()
        local venv = vim.fn.getcwd() .. '/.venv/bin/python'
        if vim.fn.executable(venv) == 1 then
          return venv
        end
        return vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python'
      end

      require('dap-python').setup(debugpy_python())
    end,
  },
}
