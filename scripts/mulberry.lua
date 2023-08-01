---- Mulberry v0.0.3
--
-- https://github.com/b0o/mulberry
--
-- Mulberry is a single-file BDD testing library for Lua targeting Neovim.
-- It's still alpha software. Don't rely on it, it's not fully tested and
-- surely has bugs. You've been warned.
--
-- Copyright 2021-2023 Maddison Hellstrom
-- Released under the MIT License

local operators = {}
local matchers = {}

---- Helpers

local function runMatcher(matcherFuncs, ...)
  if type(matcherFuncs) ~= 'table' then
    matcherFuncs = { matcherFuncs }
  end
  local res = true
  for _, m in ipairs(matcherFuncs) do
    if type(m) == 'table' then
      res = res and runMatcher(m, ...)
    else
      res = res and m(...)
    end
  end
  return res
end

local function alias(dest, to, from)
  from = type(from) == 'table' and from or { from }
  for _, f in ipairs(from) do
    dest[f] = to
  end
end

local function aliasM(...)
  return alias(matchers, ...)
end

local function aliasO(...)
  return alias(operators, ...)
end

------ Operators
-- An operator can do any of the following:
--  - Nothing
--  - Change the result returned from upstream (e.g. inversion in the case of Not)
--  - Change the set of matchers that are in scope
--  - TODO: Change the set of operators that are in scope
--  - TODO: Temporarily overload the current scope
--
-- A 'scope' refers to what can be indexed off of the Expect chain, e.g. in the
-- following, indexing 'A' changes the matcher scope to include only
-- type-related matchers:
--
--   Expect(42).To.Be.A.Number()
--
-- In fact, Number in this example isn't even a real element of 'A', it's a
-- virtual index matched against the type() of the 'actual' value (42) via the
-- __index metamethod.
--
-- This works because `A` changes the scoped `Expect.matchers` table itself wherein
-- any metamethod can be defined, such as __index. However, note that in order
-- for a matcher to be found by Expect, a non-nil index or __index for a given
-- key must be callable. That is, in `Expect(42).To.Be.A.Number()`, the `Number`
-- index on the new matchers table must be non-nil and callable.

---- Passthroughs
-- Passthrough operators do nothing useful. They exist to help construct Expect
-- chains that make sense in natural language.

operators.To = function(...)
  return ...
end
aliasO(operators.To, { 'Be', 'Than', 'Have', 'Is' })

---- Connectives

-- Unary

operators.Not = function(v)
  return not v
end

-- Binary

-- TODO: Conjunction
-- Both, Each, All
-- Usage: Expect(8).To.Both {
--          Be.LessThan(10),
--          And.Be.GreaterThan(2), -- The And prefix is optional
--        }
--

-- TODO: Disjunction
-- Either, Any
-- Usage: Expect(8).To.Be.Either {
--          Is.LessThan(10),
--          Or.Is.Both {         -- The Or prefix is optional
--            Is.GreaterThan(2),
--            Is.Even,
--        }

-- TODO: Implication
-- Note: Implication can be somewhat non-intuitive; if the antecedent
--        (left-hand side) is false, then the expectation is satisfied even if
--        the consequent (right-hand side) is also false.
--
-- Usage: Expect.That.If(antecedent).Is.A.String.Then(consequent).Is.A.Number()

---- Modifiers

-- `A` brings into scope the type and type-related matchers
operators.A = setmetatable({}, {
  __index = function(self, k)
    return rawget(self, k) or function(actual)
      return type(actual) == string.lower(k)
    end
  end,
})
operators.An = operators.A

-- A table that only has integer keys
-- The empty table is a ListLike
operators.A.ListLike = {
  operators.A.Table,
  function(actual)
    return vim.tbl_islist(actual)
  end,
}

-- A table that only has kv pairs
-- The empty table is not DictLike
operators.A.DictLike = {
  operators.A.Table,
  function(actual)
    return not runMatcher(operators.A.ListLike, actual)
  end,
}

operators.An.Int = {
  operators.A.Number,
  function(actual)
    return math.floor(actual) == actual
  end,
}
operators.An.Integer = operators.An.Int

-- A NaturalNumber is an integer in the set n >= 0
operators.A.NaturalNumber = {
  operators.An.Int,
  function(actual)
    return actual >= 0
  end,
}

-- All elements are of the given type
operators.A.TypedList = {
  operators.A.ListLike,
  function(actual, expected)
    if vim.tbl_isempty(actual) then
      return true
    end
    for _, v in ipairs(actual) do
      if type(v) ~= expected then
        return false
      end
    end
    return true
  end,
}

-- All elements are of the same primitive type
operators.A.UniformList = function(actual)
  return runMatcher(operators.A.TypedList, actual, type(actual[1]))
end

operators.A.TypedDict = {
  operators.A.DictLike,
  function(actual, expected)
    if vim.tbl_isempty(actual) then
      return false
    end
    local ex_k = expected[1]
    local ex_v = expected[2]
    for k, v in pairs(actual) do
      if type(k) ~= ex_k or type(v) ~= ex_v then
        return false
      end
    end
    return true
  end,
}

-- For a dict of {key = value} pairs, all keys are the same primitive type and
-- all values are the same primitive type
operators.A.UniformDict = function(actual)
  local keys = vim.tbl_keys(actual)
  if #keys == 0 then
    return false
  end
  return runMatcher(operators.A.TypedDict, actual, { type(keys[1]), type(actual[keys[2]]) })
end

---- Comparison

matchers.Equal = function(actual, expected)
  return actual == expected
end

matchers.DeepEqual = function(actual, expected)
  return vim.deep_equal(actual, expected)
end

--- Types

matchers.OfType = function(actual, expected)
  return type(actual) == expected
end

---- Identities

local id = function(v)
  return function(actual)
    return actual == v
  end
end

matchers.Zero = id(0)
matchers.One = id(1)

matchers.True = id(true)
matchers.False = id(false)

matchers.Nil = id(nil)

matchers.Empty = function(actual)
  return #actual == 0
end

matchers.EmptyString = {
  operators.A.String,
  matchers.Empty,
}

matchers.EmptyTable = {
  operators.A.Table,
  matchers.Empty,
}

---- Booleans

-- Falsy matches the following values:
--  - nil
--  - false
--  - 0
--  - '' (the empty string)
matchers.Falsy = function(actual)
  return not actual or actual == 0 or actual == ''
end

-- Anything that isn't Falsy is Truthy
matchers.Truthy = function(actual)
  return not runMatcher(matchers.Falsy, actual)
end

---- Numbers

matchers.Gt = function(actual, expected)
  return actual > expected
end
aliasM(matchers.Gt, { '>', 'Greater', 'GreaterThan' })

matchers.Lt = function(actual, expected)
  return actual < expected
end
aliasM(matchers.Lt, { '<', 'Less', 'LessThan' })

matchers.Ge = function(actual, expected)
  return actual >= expected
end
aliasM(matchers.Ge, { '>=', 'GreaterEq', 'GreaterThanOrEqual', 'GreaterThanOrEqualTo' })

matchers.Le = function(actual, expected)
  return actual <= expected
end
aliasM(matchers.Le, { '<=', 'LessEq', 'LessThanOrEqual', 'LessThanOrEqualTo' })

matchers.InRangeInclusive = function(actual, low, high)
  return actual >= low and actual <= high
end
aliasM(matchers.InRangeInclusive, { 'InRange' })

matchers.InRangeExclusive = function(actual, low, high)
  return actual > low and actual < high
end

matchers.InRangeLeftExclusive = function(actual, low, high)
  return actual > low and actual <= high
end

matchers.InRangeRightExclusive = function(actual, low, high)
  return actual >= low and actual < high
end

-- Positive numbers are the set n < 0
matchers.Negative = {
  operators.A.Number,
  function(actual)
    return actual < 0
  end,
}

-- Positive numbers are the set n > 0
matchers.Positive = {
  operators.A.Number,
  function(actual)
    return actual > 0
  end,
}

matchers.Even = {
  operators.An.Int,
  function(actual)
    return actual % 2 == 0
  end,
}

matchers.Odd = {
  operators.An.Int,
  function(actual)
    return actual % 2 == 1
  end,
}

---- Tables

matchers.HaveMetatable = function(actual)
  return getmetatable(actual) ~= nil
end

matchers.HaveField = {
  operators.A.Table,
  function(actual, expected, t, ...)
    local v = actual[expected]
    if v == nil then
      return false
    end
    if t then
      if type(t) == 'string' then
        return type(v) == t
      elseif type(t) == 'function' then
        return t(v)(expected, ...)
      elseif type(t) == 'table' and getmetatable(t) and type(getmetatable(t).__call) == 'function' then
        return t(v)(expected, ...)
      end
      assert(false, 'HaveField: invalid argument t: ' .. tostring(t))
    end
    return true
  end,
}

matchers.HaveFields = {
  operators.A.Table,
  function(actual, expected)
    for _, f in ipairs(expected) do
      f = type(f) == 'table' and f or { f }
      if not runMatcher(matchers.HaveField, actual, unpack(f)) then
        return false
      end
    end
    return true
  end,
}

matchers.HaveFieldPath = {
  operators.A.Table,
  function(actual, expected, t)
    local path = vim.split(expected, '.', true)
    local cur = actual
    local next
    for _, p in ipairs(path) do
      cur = next and cur[next] or cur
      if cur == nil then
        return false
      end
      local ident, index = string.match(p, '(.*)%[(%d+)%]$')
      if ident and index then
        cur = cur[ident]
        if cur == nil then
          return false
        end
        next = tonumber(index)
      else
        next = p
      end
    end
    return runMatcher(matchers.HaveField, cur, next, t)
  end,
}

matchers.HaveFieldPaths = function(actual, expected)
  for _, p in ipairs(expected) do
    p = type(p) == 'table' and p or { p }
    if not runMatcher(matchers.HaveFieldPath, actual, unpack(p)) then
      return false
    end
  end
  return true
end

---- Strings

matchers.Match = function(actual, expected)
  if type(expected) == 'userdata' then
    -- Assume a userdata is a vim.regex
    return expected:match_str(actual)
  end
  return vim.fn.match(actual, expected) >= 0
end

---- Tables and Strings

local function list_contains(t, value)
  if vim.list_contains then
    return vim.list_contains(t, value)
  end
  -- for nvim < v0.10
  for _, v in ipairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

matchers.In = function(actual, expected)
  if type(expected) == 'table' then
    return expected[actual] ~= nil or list_contains(expected, actual)
  end
  if type(expected) == 'string' or type(expected) == 'userdata' then
    return runMatcher(matchers.Match, expected, actual)
  end
  return false
end

matchers.Include = function(actual, expected)
  return runMatcher(matchers.In, expected, actual)
end

matchers.Length = function(actual, expected)
  return #actual == expected
end

matchers.LongerThan = function(actual, expected)
  return #actual > expected
end

matchers.ShorterThan = function(actual, expected)
  return #actual < expected
end

matchers.AtLeastLongerThan = function(actual, expected)
  return #actual >= expected
end

matchers.AtLeastShorterThan = function(actual, expected)
  return #actual <= expected
end

---- Functions

matchers.EvaluateTo = function(actual)
  actual = (type(actual) == 'table' and not getmetatable(actual)) and actual or { actual }
  assert(#actual > 0, 'EvaluateTo: Cannot evaluate empty list')
  local fn = table.remove(actual, 1)
  local res = { pcall(fn, unpack(actual)) }
  local ok = table.remove(res, 1)
  -- TODO: Check {...}
  return ok
end

matchers.Evaluate = function(actual)
  return runMatcher(matchers.EvaluateTo, actual)
end

matchers.ThrowError = function(actual)
  local ok = pcall(actual)
  return not ok
end

------ Test Runner Machinery
-- TODO: Matchers
--  - Throw()
--  - CalledWith()
-- TODO: support lifecycle events:
--  - BeforeSuite
--  - BeforeEach
--  - AfterEach
--  - AfterSuite
--  - etc...
-- TODO: Nested Describes
-- TODO: Helpers for mocks, stubs
-- TODO: User extensions:
--  - Matchers
--  - Operators
-- TODO: Pluggable formatters
-- TODO: TestData loading
-- TODO: Perf/Benchmark testing
-- TODO: Random pinning
-- TODO: Date pinning

local function indent(n, s, p)
  p = p or n > 0 and '│ ' or ''
  local i = string.rep(p, n)
  return table.concat(
    vim.tbl_map(function(l)
      return i .. l
    end, vim.split(s, '\n')),
    '\n'
  )
end

local function log(ctx, ...)
  print(indent(ctx.level - 1, table.concat { ... }))
end

local function traceback(...)
  return vim.tbl_map(function(l)
    return string.gsub(l, '\t', '  ')
  end, vim.split(debug.traceback(...), '\n'))
end

-- TODO: Return a 'result' table, delegate formatting to a Formatter
local function compare(op, actual, expected, name, desc, ctx)
  local res = op(actual, unpack(expected))
  if res then
    return true
  end

  local msg = { ('FAIL: Expected %s %s'):format(name, desc) }

  local function inspect(...)
    local max = 512
    local s = vim.inspect(...)
    if #s > max then
      return string.sub(s, 1, max / 2)
        .. '\n\n... ['
        .. #s - max
        .. ' chars snipped] ...\n\n'
        .. string.sub(s, #s - max / 2)
    end
    return s
  end

  for i, e in ipairs(expected) do
    local prefix = i == 1 and '' or 'Arg ' .. i - 1 .. ': '
    local s = indent(4, ('%s%s<%s> = %s'):format(prefix, name, type(e), inspect(e)), '  ')
    table.insert(msg, s)
  end

  local s = indent(4, ('%s<%s> = %s'):format(name, type(actual), inspect(actual)), '  ')
  vim.list_extend(msg, { '      but got', s })
  vim.list_extend(msg, traceback('', 2))
  table.insert(msg, '')
  log(ctx, indent(1, table.concat(msg, '\n')))

  return false
end

local expect = {}

expect.__index = function(self, k)
  if rawget(self, k) then
    return rawget(self, k)
  end

  if self.scope.operators[k] then
    self.desc = vim.list_extend(self.desc, { k })
    local op = self.scope.operators[k]
    if type(op) == 'function' then
      self.operators = vim.list_extend({ op }, self.operators)
    elseif type(op) == 'table' then
      self.scope.matchers = op
    end
    return self
  end

  if self.scope.matchers[k] then
    self.desc = vim.list_extend(self.desc, { k })
    self.matcher = self.scope.matchers[k]
    return self
  end

  -- self.actual might be nil
  if k == 'actual' then
    return rawget(self, 'actual')
  end

  error('Matcher/operator found: ' .. k .. '\n')
end

expect.__tostring = function(self)
  return table.concat(
    vim.tbl_map(function(d)
      local chars = vim.split(d, '')
      if #chars > 0 then
        chars[1] = string.lower(chars[1])
      end
      return table.concat(chars, '')
    end, self.desc),
    ' '
  )
end

expect.__call = function(self, ...)
  assert(self.matcher ~= nil, 'No matcher specified')
  assert(#self.operators > 0, 'No operators specified')
  local expected = { ... }
  local f = function(...)
    local res = runMatcher(self.matcher, ...)
    for _, op in ipairs(self.operators) do
      res = op(res)
    end
    return res
  end
  local res = compare(f, self.actual, expected, self.name, tostring(self), self.ctx)
  self.ctx:report(res)
  return res
end

local function ExpectFactory(ctx)
  return function(...)
    local args = { ... }
    local name, actual
    if #args == 1 then
      name = 'value'
      actual = args[1]
    else
      name = args[1]
      actual = args[2]
    end

    return setmetatable({
      ctx = ctx,
      actual = actual,
      name = name or 'value',
      desc = {},
      scope = {
        matchers = matchers,
        operators = operators,
      },
      operators = {},
      matcher = nil,
    }, expect)
  end
end

---- Scope

local Scope = {}

function Scope.open(outer)
  local self = {
    outer = outer or _G,
    shadowed = {},
    idents = {},
  }
  return setmetatable(self, { __index = Scope })
end

function Scope:assign(ident, value)
  self.shadowed[ident] = self.outer[ident]
  self.idents[ident] = true
  self.outer[ident] = value
end

function Scope:unassign(...)
  for _, ident in ipairs { ... } do
    self.outer[ident] = self.shadowed[ident]
    self.idents[ident] = nil
    self.shadowed[ident] = nil
  end
end

function Scope:hide(...)
  for _, ident in ipairs { ... } do
    self:assign(ident, nil)
  end
end

-- Note: A scope can't be re-used after it is closed
function Scope:close()
  self:unassign(unpack(vim.tbl_keys(self.idents)))
end

---- Context

local Context = {}

function Context.new(opts)
  local self = vim.tbl_extend('force', {
    leaf = false,
    level = 0,
    pass = 0,
    fail = 0,
    children = {},
    leaves = {},
    parent = nil,
  }, opts or {})
  return setmetatable(self, { __index = Context })
end

function Context:report(result)
  if result then
    self.pass = self.pass + 1
  else
    self.fail = self.fail + 1
  end
end

function Context:newChild(opts)
  assert(not self.leaf, 'Context:newChild: cannot add child to leaf node')
  opts = opts or {}
  opts.parent = self
  opts.id = #self.children + 1
  opts.leaf = false
  opts.level = self.level + 1
  local child = Context.new(opts)
  table.insert(self.children, child)
  return child
end

function Context:newLeaf(opts)
  assert(not self.leaf, 'Context:newLeaf: cannot add leaf to leaf node')
  opts = opts or {}
  opts.parent = self
  opts.id = #self.leaves + 1
  opts.leaf = true
  opts.level = self.level
  local leaf = Context.new(opts)
  table.insert(self.leaves, leaf)
  return leaf
end

function Context:results()
  if self.leaf then
    return {
      fail = self.fail > 0 and 1 or 0,
      pass = self.fail == 0 and 1 or 0,
      ok = self.fail == 0 and 1 or 0,
    }
  end
  local res = {
    fail = self.fail,
    pass = self.pass,
  }
  for _, c in ipairs(self.leaves) do
    local cres = c:results()
    res.fail = res.fail + cres.fail
    res.pass = res.pass + cres.pass
  end
  for _, c in ipairs(self.children) do
    local cres = c:results()
    res.fail = res.fail + cres.fail
    res.pass = res.pass + cres.pass
  end
  res.ok = res.fail == 0
  return res
end

---- Suite

local WhichFactory = function(exp)
  local make = function()
    return setmetatable({
      queue = {},
    }, {
      __index = function(self, k)
        if rawget(self, k) then
          return rawget(self, k)
        end
        table.insert(self.queue, k)
        return self
      end,
      __call = function(self, actual)
        local x = exp(actual)
        for _, q in ipairs(self.queue) do
          x = x[q]
        end
        return x
      end,
    })
  end
  return setmetatable({}, {
    __index = function(_, k)
      return make()[k]
    end,
  })
end

local function ItFactory(parentCtx)
  return function(desc, fn)
    local ctx = parentCtx:newLeaf()
    log(ctx, '├── It ' .. desc)
    local exp = ExpectFactory(ctx)
    local which = WhichFactory(exp)
    local scope = Scope.open()
    scope:hide 'It'
    scope:assign('Expect', exp)
    scope:assign('Which', which)
    fn()
    scope:close()
  end
end

local function DescribeFactory(parentCtx)
  return function(desc, fn)
    local ctx = parentCtx:newChild()
    if (ctx.level > 1 and ctx.id == 1) or (ctx.level == 1 and ctx.id > 1) then
      log(ctx, ' ')
    end
    log(ctx, '┌ Describe ' .. desc)

    local scope = Scope.open()
    scope:assign('Describe', DescribeFactory(ctx))
    scope:assign('It', ItFactory(ctx))
    fn()
    scope:close()

    local results = ctx:results()
    local pass = results.fail == 0
    log(
      ctx,
      '╰─'
        .. (pass and '■' or '□')
        .. ' '
        .. vim.fn.printf('%.6s', results.pass)
        .. ' Passed'
        .. (pass and '' or ' / ' .. results.fail .. ' Failed\n')
    )
    if ctx.level > 1 then
      log(ctx, '')
    end
    return ctx
  end
end

---- Runner

local Runner = {
  opts = {
    rootdir = vim.fn.getcwd(),
    testdir = 'test',
  },
}

function Runner.setup(opts)
  Runner.opts = vim.tbl_extend('force', Runner.opts, opts or {})
  vim.o.runtimepath = vim.o.runtimepath .. ',' .. Runner.opts.rootdir
  return Runner
end

function Runner.runFn(fn, ...)
  local args = { ... }
  local ok, res = xpcall(function()
    local ctx = Context.new()
    local scope = Scope.open()
    scope:assign('Describe', DescribeFactory(ctx))
    scope:assign('traceback', traceback)
    fn(unpack(args))
    scope:close()
    return ctx
  end, debug.traceback)

  if not ok then
    if type(res) == 'string' then
      print(res)
    elseif type(res) == 'table' then
      print(table.concat(res, '\n'))
    end
    vim.cmd 'cquit'
  end

  local results = res:results()
  if not results.ok then
    vim.cmd 'cquit'
  end
end

function Runner.runFile(file)
  local ops = {
    function()
      return not string.match(file, '%.lua$') and file .. '.lua' or file
    end,
    function()
      return table.concat({
        Runner.opts.rootdir,
        Runner.opts.testdir,
        (not string.match(file, '%.lua$') and file .. '.lua' or file),
      }, '/')
    end,
  }
  local foundFile = file
  while vim.fn.filereadable(foundFile) == 0 do
    assert(#ops > 0, 'File not found: ' .. file)
    foundFile = table.remove(ops, 1)()
  end
  Runner.runFn(function()
    local lines = { 'return {xpcall(function()', unpack(vim.fn.readfile(foundFile)) }
    table.insert(lines, 'end, traceback)}')
    local i = 1
    local f = load(function()
      local l = lines[i]
      if l == nil then
        return
      end
      i = i + 1
      return l .. '\n'
    end)
    local ok, res = unpack(f())
    if not ok then
      error(res)
    end
    return res
  end, foundFile)
end

function Runner.runFiles(files)
  for i, f in ipairs(files) do
    if i > 1 then
      print ' \n'
    end
    Runner.runFile(f)
  end
end

function Runner.runDir(dir, files)
  if not (files and #files > 0) then
    files = vim.fn.readdir(dir, function(n)
      return string.match(n, '%.lua$') and 1 or 0
    end)
  end
  return Runner.runFiles(vim.tbl_map(function(file)
    return dir .. '/' .. file
  end, files))
end

function Runner.run(files)
  files = type(files) == 'table' and files or { files }
  if files and #files > 0 then
    Runner.runFiles(files)
  else
    Runner.runDir(Runner.opts.rootdir .. '/' .. Runner.opts.testdir)
  end
  print 'All passed!'
  vim.cmd 'quit'
end

return Runner
