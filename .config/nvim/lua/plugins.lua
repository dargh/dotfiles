local function setup_plugins()
    return require('packer').startup(function(use)
        use 'wbthomason/packer.nvim'
        use 'neovim/nvim-lspconfig'
        use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } }
        use 'Mofiqul/dracula.nvim'
        use 'hrsh7th/nvim-cmp'
        use 'hrsh7th/cmp-nvim-lsp'
        use 'hrsh7th/cmp-buffer'
        use 'hrsh7th/cmp-path'
        use 'saadparwaiz1/cmp_luasnip'
        use 'L3MON4D3/LuaSnip'
    end)
end
setup_plugins()
