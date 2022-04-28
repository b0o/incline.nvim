local a = vim.api
return function(props)
  local bufname = a.nvim_buf_get_name(props.buf)
  local res = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t') or '[No Name]'
  if a.nvim_buf_get_option(props.buf, 'modified') then
    res = res .. ' [+]'
  end
  return res
end
