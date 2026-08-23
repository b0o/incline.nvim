Describe('the incline.manager module', function()
  local incline = require 'incline'
  local manager = require 'incline.manager'

  local setup = function()
    incline.setup {
      debounce_threshold = 0,
      hide = { cursorline = false },
      render = function()
        return 'incline'
      end,
    }
    vim.wait(10)
  end

  local cleanup = function(buffers)
    incline.disable()
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, false))
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end

  It('should track a window when its ignored buffer is replaced', function()
    local target_win = vim.api.nvim_get_current_win()
    local terminal_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_open_term(terminal_buf, {})
    vim.api.nvim_win_set_buf(target_win, terminal_buf)

    setup()

    Expect(manager.win_get_winline(target_win)).To.Be.Nil()

    local file_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(file_buf, 'test.txt')
    vim.api.nvim_win_set_buf(target_win, file_buf)
    vim.wait(10)

    Expect(manager.win_get_winline(target_win) ~= nil).To.Be.True()

    vim.api.nvim_win_set_buf(target_win, terminal_buf)
    vim.wait(10)

    Expect(manager.win_get_winline(target_win)).To.Be.Nil()

    cleanup { terminal_buf, file_buf }
  end)

  It('should track windows restored from a session', function()
    local target_win = vim.api.nvim_get_current_win()
    local file_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(file_buf, vim.fn.tempname())
    vim.api.nvim_win_set_buf(target_win, file_buf)

    local session_path = vim.fn.tempname()
    vim.cmd.mksession { args = { session_path }, bang = true }

    local special_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(target_win, special_buf)

    setup()

    Expect(manager.win_get_winline(target_win)).To.Be.Nil()

    vim.cmd.source(session_path)
    target_win = vim.api.nvim_get_current_win()
    vim.wait(10)

    Expect(manager.win_get_winline(target_win) ~= nil).To.Be.True()

    vim.fn.delete(session_path)
    cleanup { special_buf, file_buf }
  end)
end)
