local status_ok, trouble = pcall(require, "trouble")
if not status_ok then
  vim.notify("Failed to load trouble plugin", vim.log.levels.ERROR)
  return
end

-- Setup with default options
trouble.setup{}

-- Keymappings
vim.keymap.set("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", {silent = true, noremap = true, desc = "Diagnostics (Trouble)"})
vim.keymap.set("n", "<leader>tb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", {silent = true, noremap = true, desc = "Buffer Diagnostics (Trouble)"})
vim.keymap.set("n", "<leader>ts", "<cmd>Trouble symbols toggle focus=false<cr>", {silent = true, noremap = true, desc = "Symbols (Trouble)"})
vim.keymap.set("n", "<leader>tl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", {silent = true, noremap = true, desc = "LSP Definitions / references / ... (Trouble)"})
vim.keymap.set("n", "<leader>tL", "<cmd>Trouble loclist toggle<cr>", {silent = true, noremap = true, desc = "Location List (Trouble)"})
vim.keymap.set("n", "<leader>tq", "<cmd>Trouble qflist toggle<cr>", {silent = true, noremap = true, desc = "Quickfix List (Trouble)"})

print("Trouble setup complete")
