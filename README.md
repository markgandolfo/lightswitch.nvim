# LightSwitch.nvim

A simple and elegant Neovim plugin that provides a UI for toggling various options using the `nui.nvim` library.

[lightswitch.nvim.webm](https://github.com/user-attachments/assets/5a560a88-cdb4-4912-8d8d-981923af98ec)

## Features

- Toggle various Neovim commands/options through a sleek slider UI interface
- Navigate through options and toggle them on/off with intuitive slider controls
- Search functionality to filter visible options
- Fully customisable with your own toggles

## Prerequisites

- Neovim >= 0.7.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'markgandolfo/lightswitch.nvim',
  requires = { 'MunifTanjim/nui.nvim' }
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'markgandolfo/lightswitch.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' },
  config = function()
    require('lightswitch').setup()
  end
}
```

## Usage

1. Set up the plugin with your desired toggles:

```lua
require('lightswitch').setup({
  toggles = {
    {
      name = "Copilot",
      enable_cmd = "Copilot enable",
      disable_cmd = "Copilot disable",
      state = true -- Initially enabled
    },
    {
      name = "LSP",
      enable_cmd = ":LspStart<CR>",
      disable_cmd = ":LspStop<CR>",
      state = false -- Initially disabled
    },
    {
      name = "Treesitter",
      enable_cmd = ":TSEnable<CR>",
      disable_cmd = ":TSDisable<CR>",
      state = true -- Initially enabled
    },
    {
      name = "Diagnostics",
      enable_cmd = "lua vim.diagnostic.enable()",
      disable_cmd = "lua vim.diagnostic.disable()",
      state = true
    },
    {
      name = "Formatting",
      enable_cmd = "lua vim.g.format_on_save = true",
      disable_cmd = "lua vim.g.format_on_save = false",
      state = false
    }
  }
})
```


2. Open the LightSwitch UI:

```
:LightSwitchShow
```

## UI Controls

- `j`/`k`: Navigate up and down through toggle options
- `<Space>` or `<Enter>`: Toggle the currently selected option
- `/`: Start searching to filter options (updates in real-time as you type)
- `<Esc>`: Clear search and return to main window (when in search mode) or close UI
- `q`: Close the LightSwitch UI

## UI Features

- Slider representation for toggle state:
  - ON: `[───⦿ ]` (filled circle on right)
  - OFF: `[⦾───]` (empty circle on left)
- Search filtering for quick access to specific toggles

## Customisation

### Toggle Configuration

You can add your own toggles using the setup function:

```lua
require('lightswitch').setup({
  toggles = {
    {
      name = "My Custom Option",
      enable_cmd = ":MyEnableCommand<CR>",
      disable_cmd = ":MyDisableCommand<CR>",
      state = false
    },
    -- Add more toggles here
  }
})
```

### Color Customisation

You can customize the colors used for toggle states:

```lua
require('lightswitch').setup({
  colors = {
    off = "#4a4a4a",  -- Dark grey for OFF state (default)
    on = "#00ff00"    -- Green for ON state (optional, defaults to normal text color)
  },
  toggles = {
    -- your toggles here
  }
})
```

You can also add toggles programmatically:

```lua
local lightswitch = require('lightswitch')
lightswitch.add_toggle("Diagnostics", "lua vim.diagnostic.enable()", "lua vim.diagnostic.disable()", true)
```

### Command Formats

LightSwitch supports multiple command formats for enable/disable commands:

1. **Regular Ex commands** (default):
   ```lua
   enable_cmd = "Copilot enable"
   disable_cmd = "Copilot disable"
   ```

2. **Commands with key notation** (including `<CR>`):
   ```lua
   enable_cmd = ":HighlightColors on<CR>"
   disable_cmd = ":HighlightColors off<CR>"
   ```

3. **Lua expressions**:
   ```lua
   enable_cmd = "require('nvim-highlight-colors').turnOn()"
   disable_cmd = "require('nvim-highlight-colors').turnOff()"
   ```

## Advanced Usage

### Adding Toggles for Popular Plugins

```lua
-- For Telescope
lightswitch.add_toggle("Telescope Preview", "lua vim.g.telescope_preview = true", "lua vim.g.telescope_preview = false", true)

-- For NvimTree
lightswitch.add_toggle("NvimTree Auto", "lua require('nvim-tree.view').View.float.enable()", "lua require('nvim-tree.view').View.float.disable()", false)

-- For Git Signs
lightswitch.add_toggle("Git Signs", "Gitsigns toggle_signs", "Gitsigns toggle_signs", true)
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

MIT
