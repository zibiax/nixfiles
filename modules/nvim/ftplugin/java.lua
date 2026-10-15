local jdtls = require('jdtls')

local home = os.getenv('HOME')
local workspace_dir = home .. '/.cache/jdtls-workspace/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

local mason_registry = require('mason-registry')
local jdtls_pkg = mason_registry.get_package('jdtls')
local jdtls_path = jdtls_pkg:get_install_path()

local config = {
    cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-jar', vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
        '-configuration', jdtls_path .. '/config_linux',
        '-data', workspace_dir,
    },
    root_dir = require('jdtls.setup').find_root({'.git', 'pom.xml', 'build.gradle'}),
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
}

jdtls.start_or_attach(config)
