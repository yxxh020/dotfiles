-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 검색 시 very magic 모드 (정규식 기호를 escape 없이 사용)
vim.keymap.set({ "n", "v" }, "/", "/\\v")
