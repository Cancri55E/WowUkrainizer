local _, ns = ...;

local internal = {}
ns.StringExtensions = internal

function internal.GetHash(str)
    if (str == nil or type(str) ~= "string" or str == "") then
        return -1
    end

    -- Replace multiple spaces with a single underscore
    str = string.gsub(str, "%s+", "_")
    -- Remove newlines, carriage returns, periods, and commas
    str = string.gsub(str, "[\n\r.,’`]", "")
    -- Convert text to lowercase
    str = string.lower(str)

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

function internal.ExtractNumericValuesFromString(text)
    if text == nil or text == "" then
        return text
    end

    local icons = {}
    text = string.gsub(text, "%|T(.-)%|t", function(match)
        table.insert(icons, match)
        return string.format("{icon:%s}", string.char(#icons + 64))
    end)

    local colors = {}
    text = string.gsub(text,
        "%|c([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])(.-)%|r",
        function(color, title)
            table.insert(colors, color)
            return string.format("{color:%s|%s}", string.char(#colors + 64), title)
        end)

    local numbers = {}
    text = text:gsub("(%d[%d,]*%.?%d*)", function(num)
        if (num:sub(-1) == ",") then
            table.insert(numbers, num:sub(1, -2))
            return string.format("{%d},", #numbers)
        else
            table.insert(numbers, num)
            return string.format("{%d}", #numbers)
        end
    end)

    for i = 1, #icons do
        text = text:gsub(string.format("{icon:%s}", string.char(i + 64)), "|T" .. icons[i] .. "|t")
    end

    for i = 1, #colors do
        text = text:gsub(string.format("{color:%s", string.char(i + 64)), "{" .. colors[i])
    end

    return text, numbers
end

function internal.InsertNumericValuesIntoString(str, values)
    local result = str:gsub("{(%d+)}", function(index)
        return values[tonumber(index)]
    end)

    return result:gsub("{(%x+)|([^}]+)}", "|c%1%2|r")
end
