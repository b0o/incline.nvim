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

function Schema:parse(data, base, path)
  data = data or {}
  base = base or self.schema
  path = path or ''
  local keys = {}
  for _, k in ipairs(vim.list_extend(vim.tbl_keys(data), vim.tbl_keys(base))) do
    keys[k] = true
  end
  local res = {}
  for k in pairs(keys) do
    local p = path ~= '' and (path .. '.' .. k) or k
    local vd = data[k]
    local vb = base[k]
    assert(type(vb) == 'table', 'invalid field: ' .. p)
    if vb.parent == self then
      if vd ~= nil then
        assert(vb.validate(vd), 'invalid value for field ' .. p)
        if vb.transform then
          vd = vb.transform(vd)
        end
        res[k] = vd
      else
        res[k] = vb.default
      end
    else
      res[k] = self:parse(vd, vb, p)
    end
  end
  return setmetatable(res, {
    __index = function(_, k)
      error(('%s: invalid key: %s'):format(self.name, k))
    end,
  })
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
