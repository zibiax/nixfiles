local last_snapshot = vim.fn.stdpath('data') .. '/last-snapshot-date'

vim.api.nvim_create_user_command(
  'PluginUpdate',
  function()
    local packer = require('packer')
    local name = vim.fn.strftime('%Y-%m-%d@%H:%M:%S')

    packer.snapshot(name)
    vim.fn.writefile({name}, last_snapshot)

    local timer = vim.loop.new_timer()
    local wait_ms = 1000

    timer:start(wait_ms, 0, function()
      timer:stop()
      timer:close()
      packer.sync()
    end)
  end,
  {}
)

vim.api.nvim_create_user_command(
  'PluginRestore',
  function()
    local ok, name = pcall(vim.fn.readfile, last_snapshot, 1)
    if not ok then return end

    require('packer').rollback(name[1])
  end,
  {}
)
