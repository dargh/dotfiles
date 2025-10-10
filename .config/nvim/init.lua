local ok, packer = pcall(require, 'packer')
if not ok then
    return
end

-- Charge la liste des plugins
require('plugins')

-- Fonction de configuration qui sera appelée APRÈS que tous les plugins soient chargés
local function setup_config()
    require('config.cmp')
    require('config.lsp')
    require('config.telescope')
    vim.cmd('colorscheme dracula')
end

-- Si Packer est déjà complété (ex: 2e lancement de Nvim), configure immédiatement
if packer.loaded then
    setup_config()
else
    -- Sinon, attend l'événement de fin d'installation/synchronisation de Packer
    vim.api.nvim_create_autocmd('User', {
        pattern = 'PackerCompileDone',
        callback = setup_config,
        once = true
    })
    vim.api.nvim_create_autocmd('User', {
        pattern = 'PackerComplete',
        callback = setup_config,
        once = true
    })
end

