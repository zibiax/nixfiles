-- Mason's prebuilt binaries don't run on NixOS, there servers come from the flake
if not vim.g.nix then
    require('mason').setup()
    require('mason-lspconfig').setup({
        ensure_installed = { 'jdtls' },
        -- jdtls is started by nvim-jdtls in ftplugin/java.lua
        automatic_enable = { exclude = { 'jdtls' } },
    })
end

-- Use the new vim.lsp.config API directly (nvim 0.11+)
vim.lsp.config('pylsp', {
    cmd = { 'pylsp' },
    filetypes = { 'python' },
    root_dir = vim.fs.root(0, {'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git'}),
})

vim.lsp.config('clangd', {
    cmd = { 'clangd' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_dir = vim.fs.root(0, {'compile_commands.json', 'compile_flags.txt', '.git'}),
})

-- Enable the LSP servers
vim.lsp.enable('pylsp')
vim.lsp.enable('clangd')

-- Setup nvim-cmp
local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}

cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
    }),
    sources = {
        {name = 'nvim_lsp'},
        {name = 'buffer'},
    }
})

-- Setup LSP keymaps
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local opts = {buffer = bufnr, remap = false}
        
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<C-h>", vim.lsp.buf.signature_help, opts)
    end
})

-- Diagnostic configuration
vim.diagnostic.config({
    virtual_text = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = 'E',
            [vim.diagnostic.severity.WARN] = 'W',
            [vim.diagnostic.severity.HINT] = 'H',
            [vim.diagnostic.severity.INFO] = 'I',
        }
    }
})
