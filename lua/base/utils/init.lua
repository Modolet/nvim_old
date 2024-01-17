local M = {}

--- Create a button entity to use with the alpha dashboard
---@param sc string The keybinding string to convert to a button
---@param txt string The explanation text of what the keybinding does
---@return table # A button entity table for an alpha configuration
function M.alpha_button(sc, txt)
  -- replace <leader> in shortcut text with LDR for nicer printing
  local sc_ = sc:gsub("%s", ""):gsub("LDR", "<Leader>")
  -- if the leader is set, replace the text with the actual leader key for nicer printing
  if vim.g.mapleader then sc = sc:gsub("LDR", vim.g.mapleader == " " and "SPC" or vim.g.mapleader) end
  -- return the button entity to display the correct text and send the correct keybinding on press
  return {
    type = "button",
    val = txt,
    on_press = function()
      local key = vim.api.nvim_replace_termcodes(sc_, true, false, true)
      vim.api.nvim_feedkeys(key, "normal", false)
    end,
    opts = {
      position = "center",
      text = txt,
      shortcut = sc,
      cursor = -2,
      width = 36,
      align_shortcut = "right",
      hl = "DashboardCenter",
      hl_shortcut = "DashboardShortcut",
    },
  }
end

--
--- Get an icon from the AstroNvim internal icons if it is available and return it
---@param kind string The kind of icon in astronvim.icons to retrieve
---@param padding? integer Padding to add to the end of the icon
---@param no_fallback? boolean Whether or not to disable fallback to text icon
---@return string icon
function M.get_icon(kind, padding, no_fallback)
  if not vim.g.icons_enabled and no_fallback then return "" end
  local icon_pack = vim.g.icons_enabled and "icons" or "text_icons"
  if not M[icon_pack] then
    M.icons = require "base.icons.nerd_font"
    M.text_icons = require "base.icons.text"
  end
  local icon = M[icon_pack] and M[icon_pack][kind]
  return icon and icon .. string.rep(" ", padding or 0) or ""
end

--- Get an empty table of mappings with a key for each map mode
---@return table<string,table> # a table with entries for each map mode
function M.empty_map_table()
  local maps = {}
  for _, mode in ipairs { "", "n", "v", "x", "s", "o", "!", "i", "l", "c", "t" } do
    maps[mode] = {}
  end
  if vim.fn.has "nvim-0.10.0" == 1 then
    for _, abbr_mode in ipairs { "ia", "ca", "!a" } do
      maps[abbr_mode] = {}
    end
  end
  return maps
end

--- Table based API for setting keybindings
---@param map_table table A nested table where the first key is the vim mode, the second key is the key to map, and the value is the function to set the mapping to
---@param base? table A base set of options to set on every keybinding
function M.set_mappings(map_table, base)
  -- iterate over the first keys for each mode
  base = base or {}
  for mode, maps in pairs(map_table) do
    -- iterate over each keybinding set in the current mode
    for keymap, options in pairs(maps) do
      -- build the options for the command accordingly
      if options then
        local cmd = options
        local keymap_opts = base
        if type(options) == "table" then
          cmd = options[1]
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, options)
          keymap_opts[1] = nil
        end
        if not cmd or keymap_opts.name then -- if which-key mapping, queue it
          if not keymap_opts.name then keymap_opts.name = keymap_opts.desc end
          if not M.which_key_queue then M.which_key_queue = {} end
          if not M.which_key_queue[mode] then M.which_key_queue[mode] = {} end
          M.which_key_queue[mode][keymap] = keymap_opts
        else -- if not which-key mapping, set it
          vim.keymap.set(mode, keymap, cmd, keymap_opts)
        end
      end
    end
  end
  if package.loaded["which-key"] then M.which_key_register() end -- if which-key is loaded already, register
end

--- Check if a plugin is defined in lazy. Useful with lazy loading when a plugin is not necessarily loaded yet
---@param plugin string The plugin to search for
---@return boolean available # Whether the plugin is available
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

return M
