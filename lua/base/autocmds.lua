local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local cmd = vim.api.nvim_create_user_command
local namespace = vim.api.nvim_create_namespace

autocmd("VimEnter", {
  desc = "Start Alpha when vim is opened with no arguments",
  group = augroup("alpha_autostart", { clear = true }),
  callback = function()
    local should_skip
    local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
    if
        vim.fn.argc() > 0                                                                                    -- don't start when opening a file
        or #lines > 1                                                                                        -- don't open if current buffer has more than 1 line
        or (#lines == 1 and lines[1]:len() > 0)                                                              -- don't open the current buffer if it has anything on the first line
        or #vim.tbl_filter(function(bufnr) return vim.bo[bufnr].buflisted end, vim.api.nvim_list_bufs()) > 1 -- don't open if any listed buffers
        or not vim.o.modifiable                                                                              -- don't open if not modifiable
    then
      should_skip = true
    else
      for _, arg in pairs(vim.v.argv) do
        if arg == "-b" or arg == "-c" or vim.startswith(arg, "+") or arg == "-S" then
          should_skip = true
          break
        end
      end
    end
    if should_skip then return end
    require("alpha").start(true, require("alpha").default_config)
    vim.schedule(function() vim.cmd.doautocmd "FileType" end)
  end,
})
