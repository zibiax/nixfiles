-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

use 'untitled-ai/jupyter_ascending.vim'

use {
  'nvim-telescope/telescope.nvim', tag = '0.1.8',
-- or                            , branch = '0.1.x',
  requires = { {'nvim-lua/plenary.nvim'} }
}

use 'nvim-tree/nvim-web-devicons'

-- Java
use 'mfussenegger/nvim-jdtls'
use 'mfussenegger/nvim-dap'
use 'rcarriga/nvim-dap-ui'
use 'theHamsta/nvim-dap-virtual-text'

--
use "marcussimonsen/let-it-snow.nvim"

use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }

use({
     "folke/trouble.nvim",
     config = function()
         require("trouble").setup {
              icons = false,
              -- your configuration comes here
              -- or leave it empty to use the default settings
              -- refer to the configuration section below
        }
      end
})

use{
  "FeiyouG/commander.nvim",
  requires = { "nvim-telescope/telescope.nvim" }
}

use { "catppuccin/nvim", as = "catppuccin" }
use {
'nvim-treesitter/nvim-treesitter',
run = function()
    local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
    ts_update()
end,
}
use('nvim-treesitter/playground')
use('theprimeagen/harpoon')
use('mbbill/undotree')
use {'tpope/vim-fugitive', ft = {'gitcommit'}}
use ("nvim-tree/nvim-tree.lua")
use("folke/zen-mode.nvim")
use ("lukas-reineke/indent-blankline.nvim")
use ("nvim-lua/plenary.nvim")
use ('tanvirtin/monokai.nvim')
use {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v1.x',
  requires = {
    -- LSP Support
    {'neovim/nvim-lspconfig'},             -- Required
    {'williamboman/mason.nvim'},           -- Optional
    {'williamboman/mason-lspconfig.nvim'}, -- Optional

    -- Autocompletion
    {'hrsh7th/nvim-cmp'},         -- Required
    {'hrsh7th/cmp-nvim-lsp'},     -- Required
    {'hrsh7th/cmp-buffer'},       -- Optional
    {'hrsh7th/cmp-path'},         -- Optional
    {'saadparwaiz1/cmp_luasnip'}, -- Optional
    {'hrsh7th/cmp-nvim-lua'},     -- Optional

    -- Snippets
    {'L3MON4D3/LuaSnip'},             -- Required
    {'rafamadriz/friendly-snippets'}, -- Optional
  }
}




use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
})

 use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install",  setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })
end)
