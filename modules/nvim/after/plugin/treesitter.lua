local parsers = { "zig", "javascript", "typescript", "c_sharp", "java",
  "python", "asm", "sql", "c", "cpp", "go", "lua", "markdown", "dockerfile", "gitignore", "markdown_inline", "vim", "query", "vimdoc", "css", "html", "htmldjango" ,}

-- Under Nix the parsers come prebuilt from nvim-treesitter.withAllGrammars
-- and the plugin dir is read-only, so never try to install any
local nix = vim.g.nix

local ok, configs = pcall(require, 'nvim-treesitter.configs')
if not ok then
  -- nvim-treesitter `main` branch (what nixpkgs may ship) dropped the configs module
  if not nix then
    require('nvim-treesitter').install(parsers)
  end
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
    end,
  })
  return
end

configs.setup {
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = nix and {} or parsers,

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = not nix,

  highlight = {
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
