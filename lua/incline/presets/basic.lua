local a = vim.api
return function(props)
  local bufname = a.nvim_buf_get_name(props.buf)
  local res = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t') or '[No Name]'
  if a.nvim_get_option_value('modified', { buf = props.buf }) then
    res = res .. ' [+]'
  end
  return res
end
