return {
  "3rd/image.nvim",
  opts = {
    backend = "kitty",
    integrations = {
      markdown = {
        enabled = true,
        download_remote_images = true,
        file_types = { "markdown", "Avante" },
      },
    },
  },
}
