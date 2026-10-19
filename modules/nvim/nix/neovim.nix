# Neovim wrapped with this config. Plugins come from nixpkgs; the few that
# aren't packaged (marked `not_in_nix` in lua/zibiax/plugins.lua) are still
# installed by vim.pack on first start.
{ lib, wrapNeovim, neovim-unwrapped, vimPlugins, configDir
, git, ripgrep, fd, gcc, nodejs, python3Packages, clang-tools, jdt-language-server
}:

wrapNeovim neovim-unwrapped {
  extraMakeWrapperArgs = "--prefix PATH : ${lib.makeBinPath [
    git ripgrep fd gcc nodejs
    python3Packages.python-lsp-server clang-tools jdt-language-server
  ]}";

  configure = {
    customRC = ''
      lua << EOF
      vim.g.nix = true
      vim.opt.rtp:prepend('${configDir}')
      vim.opt.rtp:append('${configDir}/after')
      dofile('${configDir}/init.lua')
      EOF
    '';

    packages.zibiax.start = with vimPlugins; [
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      nvim-web-devicons

      nvim-jdtls
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text

      trouble-nvim
      catppuccin-nvim
      nvim-treesitter.withAllGrammars
      harpoon
      undotree
      vim-fugitive
      nvim-tree-lua
      zen-mode-nvim
      indent-blankline-nvim

      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim

      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp_luasnip
      cmp-nvim-lua

      luasnip
      friendly-snippets

      markdown-preview-nvim
    ];
  };
}
