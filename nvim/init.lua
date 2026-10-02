-- ==============================================================================
-- Neovim Configuration (init.lua) - Based on Neovim manual 2212 & Ubuntu Best Practices
-- ==============================================================================

-- 1. 기본 편집 설정
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus' -- 시스템 클립보드 연동
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.cursorline = true

-- 2. 검색 정규식 Very Magic 모드 (매뉴얼 필수 권장)
vim.keymap.set('n', '/', '/\\v', { desc = 'Very magic search' })
vim.keymap.set('v', '/', '/\\v', { desc = 'Very magic search' })

-- 3. 편의 단축키
vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { desc = 'Quit' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })
