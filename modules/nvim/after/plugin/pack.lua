-- Rollback point is nvim-pack-lock.json, commit it before updating
vim.api.nvim_create_user_command('PluginUpdate', function()
    vim.pack.update()
end, {})

-- Reset plugins to the revisions in nvim-pack-lock.json
vim.api.nvim_create_user_command('PluginRestore', function()
    vim.pack.update(nil, { target = 'lockfile' })
end, {})

-- Delete plugins that are no longer listed in plugins.lua
vim.api.nvim_create_user_command('PluginClean', function()
    local unused = vim.iter(vim.pack.get(nil, { info = false }))
        :filter(function(p) return not p.active end)
        :map(function(p) return p.spec.name end)
        :totable()
    if #unused == 0 then
        print('No unused plugins')
        return
    end
    vim.pack.del(unused)
end, {})
