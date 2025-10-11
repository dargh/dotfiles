local on_attach = function(client, bufnr)
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
end

local servers = { 'bashls', 'lua_ls' }
for _, server_name in ipairs(servers) do
    vim.lsp.start({
        name = server_name,
        cmd = require('lspconfig')[server_name].document_config.default_config.cmd,
        on_attach = on_attach,
        root_dir = require('lspconfig.util').root_pattern('.git', vim.fn.getcwd()),
    })
end
