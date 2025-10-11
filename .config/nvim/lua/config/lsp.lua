local on_attach = function(client, bufnr)
    local opts = { buffer = bufnr, noremap = true, silent = true }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
end

local servers = {
    bashls = { cmd = { "bash-language-server", "start" } },
    lua_ls = { cmd = { "lua-language-server" } },
}

for name, opts in pairs(servers) do
    opts.name = name
    opts.on_attach = on_attach
    opts.root_dir = vim.fn.getcwd()
    vim.lsp.start(opts)
end
