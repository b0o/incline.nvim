local M = {}

---@class RGBColor
---@field r number a number between 0 and 1 inclusive
---@field g number a number between 0 and 1 inclusive
---@field b number a number between 0 and 1 inclusive

---@alias HexColor string a hex color string

---@alias Color RGBColor|HexColor

---Check if a color is a hex color. Leading # is optional.
---@param color unknown
---@return boolean
local is_hex_color = function(color)
  return type(color) == 'string' and color:match '^#?%x%x%x%x%x%x$'
end

local is_rgb_color = function(color)
  return type(color) == 'table'
    and type(color.r) == 'number'
    and type(color.g) == 'number'
    and type(color.b) == 'number'
end

---Convert a hex string to an RGB color
---@param color Color
---@return RGBColor
M.hex_to_rgb = function(color)
  if is_rgb_color(color) then
    ---@type RGBColor
    return color
  end
  assert(is_hex_color(color), 'color must be a hex color')
  assert(type(color) == 'string', 'color must be a string') -- for type checking
  local hex = color:gsub('#', ''):lower()
  return {
    r = tonumber(hex:sub(1, 2), 16) / 255,
    g = tonumber(hex:sub(3, 4), 16) / 255,
    b = tonumber(hex:sub(5, 6), 16) / 255,
  }
end

---Convert an RGBColor to a HexColor
---@param rgb RGBColor
---@return HexColor
M.rgb_to_hex = function(rgb)
  local function to_hex(channel)
    local hex = string.format('%x', math.floor(channel * 255))
    if #hex == 1 then
      hex = '0' .. hex
    end
    return hex
  end
  return '#' .. to_hex(rgb.r) .. to_hex(rgb.g) .. to_hex(rgb.b)
end

---Given a color, return its relative luminance
---@param color Color
M.relative_luminance = function(color)
  local rgb = M.hex_to_rgb(color)
  local r, g, b = rgb.r, rgb.g, rgb.b
  local function adjust(channel)
    if channel <= 0.03928 then
      return channel / 12.92
    else
      return ((channel + 0.055) / 1.055) ^ 2.4
    end
  end
  r, g, b = adjust(r), adjust(g), adjust(b)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

---@class ContrastColorOptions
---@field dark? Color (default '#000000')
---@field light? Color (default '#ffffff')
---@field threshold? number (default 0.179)

---Given a color, return either a dark or light color depending on the
---relative luminance of the input color.
---@param color Color
---@param opts? ContrastColorOptions
---@return Color
M.contrast_color = function(color, opts)
  opts = opts or {}
  local dark = opts.dark or '#000000'
  local light = opts.light or '#ffffff'
  local threshold = opts.threshold or 0.179
  if M.relative_luminance(M.hex_to_rgb(color)) > threshold then
    return dark
  else
    return light
  end
end

---Like |nvim_eval_statusline()|, but returns an Incline render result table instead.
---Same options as |nvim_eval_statusline()|, except that `opts.highlights` defaults to `true`.
---@param str string
---@param opts? {winid?: integer, maxwidth?: integer, highlights?: boolean, use_winbar?: boolean, use_tabline?: boolean, use_statuscol_lnum?: boolean}
---@return {[integer]: string, group?: string}[]
M.eval_statusline = function(str, opts)
  local _opts = opts or {}
  _opts.winid = _opts.winid or 0
  if _opts.highlights == nil then
    _opts.highlights = true
  end
  local eval_res = vim.api.nvim_eval_statusline(str, _opts)
  return M.convert_nvim_eval_statusline(eval_res)
end

---Convert the result of |nvim_eval_statusline()| to an Incline render result table.
---@param eval_tbl {str: string, highlights?: {start: integer, group: string}[]}
---@return {[integer]: string, group?: string}[]
M.convert_nvim_eval_statusline = function(eval_tbl)
  local stl_hls = eval_tbl.highlights
  if not stl_hls or #stl_hls == 0 then
    return { { eval_tbl.str } }
  end
  if stl_hls[1].start > 0 then
    table.insert(stl_hls, 1, { group = nil, start = 0 })
  end

  local hls = {}
  for i, hl in ipairs(stl_hls) do
    local start = hl.start + 1
    if i > 1 then
      hls[i - 1].range[2] = start - 1
    end
    local cur = { range = { start }, group = hl.group }
    if i == #stl_hls then
      cur.range[2] = #eval_tbl.str
    end
    table.insert(hls, cur)
  end

  local res = {}
  for _, hl in ipairs(hls) do
    local str = eval_tbl.str:sub(unpack(hl.range))
    if str ~= '' then
      table.insert(res, { str, group = hl.group })
    end
  end
  return res
end

return M
