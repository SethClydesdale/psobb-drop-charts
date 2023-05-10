local function __genOrderedIndex(t)
  local orderedIndex = {}
  for key in pairs(t) do
    table.insert(orderedIndex, tonumber(key))
  end
  table.sort(orderedIndex)
  return orderedIndex
end

local function orderedNext(t, state)
  local key = nil
  if state == nil then
    -- the first time, generate the index
    t.__orderedIndex = __genOrderedIndex(t)
    key = t.__orderedIndex[1]
  else
    -- fetch the next value
    for i = 1,table.getn(t.__orderedIndex) do
      if t.__orderedIndex[i] == state then
          key = t.__orderedIndex[i+1]
      end
    end
  end
  if key then
    return key, t[key]
  end
  -- no more value to return, cleanup
  t.__orderedIndex = nil
  return
end

local function orderedPairs(t)
  -- Equivalent of the pairs() function on tables. Allows to iterate
  -- in order
  return orderedNext, t, nil
end

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local function splitByDelimiter(str, delimiter)
  local s1, s2, found = {}, {}, false
  str = string.gsub(str, "[\n\r]", "")
  for i = 1, #str do
    if str:sub(i,i) == delimiter then
      found = true
    end
    if found ~= true and str:sub(i,i) ~= delimiter then
      table.insert(s1, str:sub(i,i))
    end
    if found == true and str:sub(i,i) ~= delimiter then
      table.insert(s2, str:sub(i,i))
    end
  end
  return {
    s1 = table.concat(s1),
    s2 = table.concat(s2) 
  }
end

return { orderedPairs = orderedPairs, copy = copy, splitByDelimiter = splitByDelimiter }