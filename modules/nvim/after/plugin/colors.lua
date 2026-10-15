-- Load the Monokai plugin and setup
require("monokai").setup({
    disable_background = true
})

-- Define a function to set colors and transparency
function ColorMyPencils(color) 
    -- Set color scheme
    color = color or "monokai" -- Default to Monokai if no color is provided
    vim.cmd.colorscheme(color)

    -- Set transparency for Normal and NormalFloat highlight groups
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

-- Call the function to apply color scheme and transparency
ColorMyPencils()

