local Schema = {}

function Schema:entry(default, validate, transform)
  return {
    parent = self,
    default = default,
    validate = validate,
    transform = transform,
  }
end

function Schema:validate(path, val)
  local target = self.schema
  for _, k in ipairs(path) do
    target = target[k]
    if type(target) ~= 'table' then
      break
    end
  end
  assert(type(target) == 'table' and target.parent == self, 'invalid field: ' .. table.concat(path, '.'))
  return target.validate(val)
end

local function _parse(self, data, fallback, schema, path)
  data = data or {}
  fallback = fallback or {}
  schema = schema or {}
  path = path or ''
  local keys = {}
  for _, k in ipairs(vim.list_extend(vim.tbl_keys(data), vim.tbl_keys(schema))) do
    keys[k] = true
  end
  local res = {}
  for k in pairs(keys) do
    local p = path ~= '' and (path .. '.' .. k) or k
    local val_data = data[k]
    local val_schema = schema[k]
    local val_fallback = fallback[k]
    assert(type(val_schema) == 'table', 'invalid field: ' .. p)
    if val_schema.parent == self then
      if val_data ~= nil then
        assert(val_schema.validate(val_data), 'invalid value for field ' .. p)
        if val_schema.transform then
          val_data = val_schema.transform(val_data)
        end
        res[k] = val_data
      elseif val_fallback ~= nil then
        res[k] = val_fallback
      else
        res[k] = val_schema.default
      end
    else
      res[k] = _parse(self, val_data, val_fallback, val_schema, p)
    end
  end
  return setmetatable(res, {
    __index = function(_, k)
      error(('%s: invalid key: %s'):format(self.name, k))
    end,
  })
end

function Schema:parse(data, fallback)
  return _parse(self, data, fallback, self.schema)
end

function Schema:default()
  return self:parse()
end

local make = function(name, schema)
  local self = setmetatable({ name = name }, { __index = Schema })
  self.schema = schema(self)
  return self
end

return make