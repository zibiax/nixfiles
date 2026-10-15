local status_ok, snow = pcall(require, "let-it-snow")
if not status_ok then
    -- If the plugin isn't available, we exit gracefully without an error
    return
end

-- Configure the plugin with default options
-- The setup function initializes the plugin and registers its commands
snow.setup({
    cmd = "LetItSnow",
    opts = {},
})
