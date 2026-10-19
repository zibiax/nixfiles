local jdtls = require('jdtls')

local home = os.getenv('HOME')
local workspace_dir = home .. '/.cache/jdtls-workspace/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

-- `jdtls` launcher script is on PATH from mason (mason/bin) or from Nix
-- (jdt-language-server), and finds its own launcher jar and config dir
local config = {
    cmd = { 'jdtls', '-data', workspace_dir },
    root_dir = vim.fs.root(0, {'.git', 'pom.xml', 'build.gradle'}),
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
}

jdtls.start_or_attach(config)
