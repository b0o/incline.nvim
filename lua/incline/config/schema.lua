local tx = require 'incline.config.transform'

local function join_path(...)
  local res = ''
  for _, p in ipairs { ... } do
    local sep = res == '' and '' or '.'
    if type(p) ~= 'string' then
      sep = ''
      p = '[' .. tostring(p) .. ']'
    end
    res = res .. sep .. p
  end
  return res
end

local M = {
  result = {
    INVALID_FIELD = 1,
    INVALID_VALUE = 2,
    INVALID_LEAF = 3,
    DEPRECATED = 4,
  },
}

local Schema = {}

function Schema:entry(default, validate, opts)
  opts = opts or {}
  if type(opts) == 'function' then
    opts = { transform = opts }
  end
  if type(opts.transform) == 'string' then
    assert(tx[opts.transform] ~= nil, 'unknown transform: ' .. opts.transform)
    opts.transform = tx[opts.transform]
  end
  return {
    parent = self,
    default = default,
    validate = validate,
    transform = opts.transform,
  }
end

function Schema:transform(transform, val)
  return {
    parent = self,
    transform = type(transform) == 'function' and transform or tx[transform],
    val = val,
  }
end

function Schema:validate_entry(data, schema, path)
  if not schema.validate(data) then
    return false, M.result.INVALID_VALUE, path
  end
  local deprecated, msg = self:is_deprecated_val(path, data)
  if deprecated then
    return false, M.result.DEPRECATED, msg
  end
  return true
end

function Schema:parse_entry(data, fallback, schema, path, opts)
  opts = opts or {}
  if data == nil then
    if fallback ~= nil then
      data = fallback
    else
      data = schema.default
    end
  end
  if opts.raw then
    return data
  end
  local transform
  if type(data) == 'table' and data.parent == self then
    if data.transform then
      transform = data.transform
    end
    data = data.val
  end
  transform = transform or schema.transform
  if transform then
    data = transform(data, schema, self)
  end
  local ok, result, msg = self:validate_entry(data, schema, path)
  if not ok then
    return result, msg
  end
  return data
end

function Schema:get_entry(key, base, path)
  local target = (base or self.schema)[key]
  if type(target) ~= 'table' then
    local deprecated, msg = self:is_deprecated_field(path)
    if deprecated then
      return nil, M.result.DEPRECATED, msg
    end
    return nil, M.result.INVALID_FIELD, path
  end
  return target
end

function Schema:parse(data, fallback, schema, path, opts)
  data = data or {}
  fallback = fallback or {}
  path = path or ''
  schema = schema or (path == '' and self.schema or {})
  if type(data) ~= 'table' then
    return M.result.INVALID_LEAF, path
  end
  local keys = {}
  for k, _ in pairs(data) do
    keys[k] = true
  end
  for k, _ in pairs(schema) do
    keys[k] = true
  end
  local res = {}
  for k in pairs(keys) do
    local inner_data = data[k]
    local inner_fallback = fallback[k]
    local inner_path = join_path(path, k)
    local inner_schema, result, msg = self:get_entry(k, schema, inner_path)
    if not inner_schema then
      return result, msg
    end
    local err
    if inner_schema.parent == self then
      res[k], err = self:parse_entry(inner_data, inner_fallback, inner_schema, inner_path, opts)
    else
      res[k], err = self:parse(inner_data, inner_fallback, inner_schema, inner_path, opts)
    end
    if err ~= nil then
      return res[k], err
    end
  end
  return setmetatable(res, {
    __index = function(_, key)
      error(('invalid key: ' .. key))
    end,
  })
end

function Schema:default(opts)
  return self:parse(nil, nil, nil, nil, opts)
end

function Schema:raw()
  return require('incline.util').tbl_plain(self:default { raw = true })
end

function Schema:is_deprecated_field(path)
  local res = self.deprecated.fields[path]
  if not res then
    return false
  end
  if type(res) ~= 'boolean' then
    return true, res
  end
  return true, 'field "' .. path .. '"'
end

function Schema:is_deprecated_val(path, val)
  local dep_obj = self.deprecated.vals[path]
  if not dep_obj then
    return false
  end
  for vx, msg in pairs(dep_obj) do
    if vx(val) then
      return true, type(msg) == 'string' and msg or ('value for field "' .. path .. '"')
    end
  end
end

local make = function(schema)
  local self = setmetatable({
    deprecated = { fields = {}, vals = {} },
  }, { __index = Schema })
  self.transforms = vim.tbl_map(function(t)
    return function(...)
      return self:transform(t, ...)
    end
  end, tx)
  local opts
  self.schema, opts = schema(self)
  opts = opts or {}
  self.deprecated = vim.tbl_deep_extend('force', self.deprecated, opts.deprecated or {})
  return self
end

return setmetatable({}, {
  __index = M,
  __call = function(_, ...)
    return make(...)
  end,
})
