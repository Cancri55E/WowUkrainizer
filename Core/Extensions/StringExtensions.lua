local _, ns = ...;

local internal = {}
ns.StringExtensions = internal

function internal.GetHash(str)
    local counter = 1
    local len = string.len(str)
    for i = 1, len, 3 do
        counter = math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
            (string.byte(str, i) * 16776193) +
            ((string.byte(str, i + 1) or (len - i + 256)) * 8372226) +
            ((string.byte(str, i + 2) or (len - i + 256)) * 3932164)
    end
    return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

function internal.EndsWith(str, suffix)
    if (not str) then return false end
    if #str < #suffix then
        return false
    else
        str = str:lower()
        suffix = suffix:lower()
        return str:sub(- #suffix) == suffix
    end
end

function internal.StartsWith(str, prefix)
    if (not str) then return false end
    if #str < #prefix then
        return false
    else
        str = str:lower()
        prefix = prefix:lower()
        return str:sub(1, #prefix) == prefix
    end
end

function internal.Split(input, delimiter)
    local items = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for item in input:gmatch(pattern) do
        table.insert(items, item)
    end
    return items
end

function internal.ExtractNumericValuesFromString(str)
    local values = {}
    local modifiedText = str:gsub("(%d[%d,]*%.?%d*)", function(num)
        table.insert(values, num)
        return "{" .. #values .. "}"
    end)

    return modifiedText, values
end

function internal.InsertNumericValuesIntoString(str, values)
    local result = str:gsub("{(%d+)}", function(index)
        return values[tonumber(index)]
    end)
    return result
end
