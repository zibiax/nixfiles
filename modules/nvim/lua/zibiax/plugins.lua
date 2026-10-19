-- Plugins are managed by the built-in vim.pack (nvim 0.12+, see :h vim.pack).
-- Pinned revisions live in nvim-pack-lock.json, keep it in git.
--
-- When started through the Nix flake (vim.g.nix is set), plugins come from
-- nixpkgs instead and vim.pack only installs the ones marked `nix = false`.

local function gh(repo, spec)
    spec = spec or {}
    spec.src = 'https://github.com/' .. repo
    return spec
end

-- Not packaged in nixpkgs, always installed by vim.pack
local function not_in_nix(spec)
    spec.data = { nix = false }
    return spec
end

local plugins = {
    not_in_nix(gh('untitled-ai/jupyter_ascending.vim')),

    gh('nvim-lua/plenary.nvim'),
    gh('nvim-telescope/telescope.nvim', { version = '0.1.8' }),
    gh('nvim-telescope/telescope-fzf-native.nvim'),
    gh('nvim-tree/nvim-web-devicons'),

    -- Java
    gh('mfussenegger/nvim-jdtls'),
    gh('mfussenegger/nvim-dap'),
    gh('rcarriga/nvim-dap-ui'),
    gh('theHamsta/nvim-dap-virtual-text'),

    --
    not_in_nix(gh('marcussimonsen/let-it-snow.nvim')),

    gh('folke/trouble.nvim'),
    not_in_nix(gh('FeiyouG/commander.nvim')),

    gh('catppuccin/nvim', { name = 'catppuccin' }),
    -- master is the branch with the `nvim-treesitter.configs` API
    gh('nvim-treesitter/nvim-treesitter', { version = 'master' }),
    gh('nvim-treesitter/playground'),
    gh('theprimeagen/harpoon'),
    gh('mbbill/undotree'),
    gh('tpope/vim-fugitive'),
    gh('nvim-tree/nvim-tree.lua'),
    gh('folke/zen-mode.nvim'),
    gh('lukas-reineke/indent-blankline.nvim'),
    not_in_nix(gh('tanvirtin/monokai.nvim')),

    -- LSP Support
    gh('neovim/nvim-lspconfig'),
    gh('williamboman/mason.nvim'),
    gh('williamboman/mason-lspconfig.nvim'),

    -- Autocompletion
    gh('hrsh7th/nvim-cmp'),
    gh('hrsh7th/cmp-nvim-lsp'),
    gh('hrsh7th/cmp-buffer'),
    gh('hrsh7th/cmp-path'),
    gh('saadparwaiz1/cmp_luasnip'),
    gh('hrsh7th/cmp-nvim-lua'),

    -- Snippets
    gh('L3MON4D3/LuaSnip'),
    gh('rafamadriz/friendly-snippets'),

    gh('iamcco/markdown-preview.nvim'),
}

-- Build steps (packer's `run`). Must be registered before vim.pack.add()
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind, path = ev.data.spec.name, ev.data.kind, ev.data.path
        if kind ~= 'install' and kind ~= 'update' then
            return
        end

        if name == 'telescope-fzf-native.nvim' then
            vim.system({ 'sh', '-c', 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' },
                { cwd = path })
        elseif name == 'markdown-preview.nvim' then
            vim.cmd.packadd(name)
            vim.fn['mkdp#util#install']()
        elseif name == 'nvim-treesitter' and kind == 'update' then
            if not ev.data.active then
                vim.cmd.packadd(name)
            end
            vim.cmd('TSUpdate')
        end
    end,
})

if vim.g.nix then
    plugins = vim.tbl_filter(function(spec)
        return spec.data and spec.data.nix == false
    end, plugins)
end

vim.g.mkdp_filetypes = { 'markdown' }

vim.pack.add(plugins)
